//
//  UMRpcHandler.m
//  ulibrpc
//
//  Created by Andreas Fink on 20.08.2026.
//

#import <ulib/UMRpcHandler.h>
#import <ulib/UMRpcSession.h>
#import <ulib/UMRpcServer.h>
#import <ulib/UMRpcClient.h>
#import <ulib/UMRpcMessage.h>
#import <ulib/UMRpcFlag.h>
#import <ulib/UMRpcMessageDecoder.h>

@implementation UMRpcHandler


- (UMRpcHandler *)initWithSocket:(UMSocket *)s
                          server:(UMRpcServer *)server
                         logFeed:(UMLogFeed *)feed
                        logLevel:(UMLogLevel)level
{
    self = [super initWithName:@"UMRpcHandler"];

    if(self)
    {
        self.logFeed = feed;
        _logLevel = level;
        _socket = s;
        _server = server;
        _maxReceiveBuffer = 10485760; /* 10MB */
        _session = [[UMRpcSession alloc]init];
        _session.socket = _socket;
        _session.server = _server;
        _session.logFeed = _logFeed;
        _session.logLevel = _logLevel;
        _messageDecoder = server.messageDecoder;
        _session.messageDecoder = _messageDecoder;

    }
    return self;
}

- (UMRpcHandler *)initWithSocket:(UMSocket *)s
                          client:(UMRpcClient *)client
                         logFeed:(UMLogFeed *)feed
                        logLevel:(UMLogLevel)level
{
    self = [super initWithName:@"UMRpcHandler"];

    if(self)
    {
        self.logFeed = feed;
        _logLevel = level;
        _socket = s;
        _client = client;
        _maxReceiveBuffer = 10485760; /* 10MB */
        _session = [[UMRpcSession alloc]init];
        _session.socket = _socket;
        _session.client = _client;
        _session.logFeed = _logFeed;
        _session.logLevel = _logLevel;
        _messageDecoder = client.messageDecoder;
        _session.messageDecoder = _messageDecoder;
    }
    return self;
}

- (void)backgroundInit
{
}

- (void)backgroundExit
{
    [_socket close];
}

- (int)work
{
    int processedData = 0;
    @autoreleasepool
    {
        UMSocketError err =  [_socket receiveToBufferWithBufferLimit:_maxReceiveBuffer];
        if( (err != UMSocketError_has_data) &&
            (err != UMSocketError_has_data_and_hup) &&
            (err != UMSocketError_no_error) &&
            (err != UMSocketError_try_again))
        {
            /* some unexpected error occured */
            NSString *s = [NSString stringWithFormat:@"error while reading %@",[UMSocket getSocketErrorString:err]];
            [_logFeed majorErrorText:s];
            [self shutdownBackgroundTaskFromWithin];
            return processedData;
        }
        ummutex_lock(_socket.dataLock);
        @try
        {
            NSUInteger pos = 0;
            if(_socket.receiveBuffer.length > 0)
            {
                UMASN1Object *o = [[UMASN1Object alloc]initWithBerData:_socket.receiveBuffer atPosition:&pos context:NULL];
                if(pos > 0)
                {
                    [_socket deleteFromReceiveBuffer:pos];
                    processedData++;
                }
                if(o)
                {
                    UMRpcMessage *cmd = [[UMRpcMessage alloc]initWithASN1Object:o context:NULL];
                    if(cmd)
                    {
                        UMSocketError err = [_session processMessage:cmd];
                        if(([cmd isFlagSet:UMRpcFlag_CLOSING_CONNECTION]) || (err))
                        {
                            [self terminateHandler];
                        }
                        else
                        {
                            processedData++;
                        }
                    }
                }
            }
        }
        @catch(NSException *e)
        {
            NSString *s = [NSString stringWithFormat:@"exception %@",e];
            [_logFeed majorErrorText:s];
        }
        ummutex_unlock(_socket.dataLock);
        if(err == UMSocketError_has_data_and_hup)
        {
            [self terminateHandler];
        }
    }
    return processedData;
}

- (void) terminateHandler
{
    _session.socket = NULL;
    _session.server = NULL;
    _session.client = NULL;
    _session = NULL;
    [self shutdownBackgroundTaskFromWithin];
}
@end

