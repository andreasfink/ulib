//
//  UMRpcServer.m
//  ulibrpc
//
//  Created by Andreas Fink on 20.08.2026.
//

#import <ulib/UMRpcServer.h>
#import <ulib/UMRpcCommandHandler.h>
#import <ulib/UMRpcHandler.h>
#import <ulib/UMRpcMessageType.h>
#import <ulib/UMRpcMessage.h>
#import <ulib/UMRpcMessage_GenericError.h>
#import <ulib/UMRpcSession.h>
#import <ulib/UMRpcSessionHandler.h>
#import <ulib/UMRpcMessageDecoder.h>
#import <ulib/UMASN1UTF8String.h>
#import <ulib/UMLogFeed.h>

@implementation UMRpcServer


- (UMRpcServer *)initWithName:(NSString *)name port:(NSInteger)port  logFeed:(UMLogFeed *)feed logLevel:(UMLogLevel)level
{
    self = [super initWithName:name];
    if(self)
    {
        self.logFeed = feed;
        _logLevel = level;
        _port = port;
        _listener = [[UMSocket alloc] initWithType:UMSOCKET_TYPE_TCP];
        _listener.localHost = [[UMHost alloc]initWithLocalhost];
        _listener.localPort = port;
        _commandHandlers = [[UMSynchronizedSortedDictionary alloc]init];
        _messageDecoder = [[UMRpcMessageDecoder alloc]init];
        _messageTypes = [_messageDecoder standardMessageTypes];
    }
    return self;
}

- (void)addCommand:(NSInteger)commandId
              name:(NSString *)name
      objectToCall:(id)obj
          selector:(SEL)selector
{
    UMRpcCommandHandler *ch = [[UMRpcCommandHandler alloc]init];
    ch.command              = commandId;
    ch.name                 = name;
    ch.objectToCall         = obj;
    ch.selectorToCall       = selector;
    _commandHandlers[@(commandId)] = ch;
    [self addMessageType:commandId name:name];
}

- (void)addMessageType:(NSInteger)commandId name:(NSString *)name
{
    _messageTypes[@(commandId)] = name;
}

- (NSString *)messageTypeName:(NSNumber *)n
{
    if(n==NULL)
    {
        return @"NULL";
    }
    NSString *s = _messageTypes[n];
    if(s==NULL)
    {
        return [NSString stringWithFormat:@"UNKNOWN(%@)",n];
    }
    return s;
}

- (UMSocketError)processRequest:(UMRpcMessage *)msg
                        session:(UMRpcSession *)session
{
    UMRpcCommandHandler *ch = _commandHandlers[msg.command];
    UMSocketError e = UMSocketError_no_error;
    if(ch==NULL)
    {
        UMRpcMessage_GenericError *resp = [[UMRpcMessage_GenericError alloc]init];
        [resp setFlag:UMRpcFlag_IS_RESPONSE];
        resp.sequenceNumber = msg.sequenceNumber;
        UMSocketError e = [session sendMessage:resp];
        return e;
    }
    if(ch.objectToCall)
    {
        if([ch.objectToCall respondsToSelector:ch.selectorToCall])
        {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            @try
            {
                NSNumber *n = [ch.objectToCall performSelector:ch.selectorToCall withObject:msg withObject:session];
                e = n.intValue;
                return e;
            }
            @catch(NSException *ex)
            {
                NSLog(@"Exception: %@",ex);
                UMRpcMessage_GenericError *resp = [[UMRpcMessage_GenericError alloc]init];
                [resp setFlag:UMRpcFlag_IS_RESPONSE];
                resp.sequenceNumber = msg.sequenceNumber;
                resp.payload = [[UMASN1UTF8String alloc]initWithString:ex.description];
                UMSocketError e = [session sendMessage:resp];
                return e;
            }
#pragma clang diagnostic pop
        }
    }
    return UMSocketError_no_error;
}


- (UMSocketError)processResponse:(UMRpcMessage *)msg
                         session:(UMRpcSession *)session
                  sessionHandler:(UMRpcSessionHandler *)sh
{
    if(sh.objectToCall)
    {
        @try
        {
            if([sh.objectToCall respondsToSelector:sh.selectorToCall])
            {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                NSNumber *n=NULL;
                if(sh.objectToAdd)
                {
                    n = [sh.objectToCall performSelector:sh.selectorToCall withObject:msg];
                }
                else
                {
                    n = [sh.objectToCall performSelector:sh.selectorToCall withObject:msg withObject:sh.objectToAdd];
                }
                return n.intValue;
            }
            return UMSocketError_no_such_process;
        }
        @catch(NSException *e)
        {
            NSLog(@"Exception: %@",e);
            return UMSocketError_io_error;
        }
    }
    return UMSocketError_no_error;
}




- (void)backgroundInit
{
    UMSocketError err = [_listener bind];
    if(err)
    {
        NSString *s = [NSString stringWithFormat:@"bind() failed with err=%@",[UMSocket getSocketErrorString:err]];
        [_logFeed majorErrorText:s];
        return;
    }
    err = [_listener listen:128];
    if(err)
    {
        NSString *s = [NSString stringWithFormat:@"listen() failed with err=%@",[UMSocket getSocketErrorString:err]];
        [_logFeed majorErrorText:s];
        return;
    }
}
- (void)backgroundExit
{
    [_listener close];
}

- (int)work
{
    @autoreleasepool
    {
        UMSocketError err = UMSocketError_no_error;
        UMSocket *newSocket = [_listener accept:&err];
        if((err!= UMSocketError_no_error) && (err!=UMSocketError_has_data) && (err!=UMSocketError_has_data_and_hup))
        {
            NSString *s = [NSString stringWithFormat:@"accept() failed with err=%@",[UMSocket getSocketErrorString:err]];
            [_logFeed majorErrorText:s];
        }
        if(newSocket)
        {
            UMRpcHandler *h = [[UMRpcHandler alloc]initWithSocket:newSocket
                                                           server:self
                                                          logFeed:_logFeed
                                                         logLevel:_logLevel];
            h.messageDecoder = _messageDecoder;
            [_incomingConnections addObject:h];
            [h startBackgroundTask];
        }
    }
    return 0;
}

@end
