//
//  UMRpcClient.m
//  ulibrpc
//
//  Created by Andreas Fink on 20.08.2026.
//

#import <ulib/UMSocket.h>
#import <ulib/UMRpcClient.h>
#import <ulib/UMRpcError.h>
#import <ulib/UMRpcClient.h>
#import <ulib/UMRpcHandler.h>
#import <ulib/UMRpcSession.h>
#import <ulib/UMRpcMessage_LoginRequest.h>
#import <ulib/UMRpcMessage_LoginResponse.h>
#import <ulib/UMRpcMessage_LogoutRequest.h>
#import <ulib/UMRpcMessage_LogoutResponse.h>
#import <ulib/UMRpcMessage_HeartbeatRequest.h>
#import <ulib/UMRpcMessage_HeartbeatResponse.h>
#import <ulib/UMRpcSessionHandler.h>
#import <ulib/UMRpcMessageType.h>
#import <ulib/UMRpcMessageDecoder.h>
#import <ulib/UMHost.h>

@implementation UMRpcClient

- (UMRpcClient *)initWithHost:(UMHost *)host
                         port:(int)port
{
    self = [super init];
    if(self)
    {
        [host resolve];
        _socket = [[UMSocket alloc]initWithType:UMSOCKET_TYPE_TCP];
        _socket.remoteHost = host;
        _socket.requestedRemotePort = port;
        _messageDecoder = [[UMRpcMessageDecoder alloc]init];
        _messageTypes = [_messageDecoder standardMessageTypes];
    }
    return self;
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

- (BOOL)isConnected
{
    return _socket.isConnected;
}

-(BOOL)isLoggedIn
{
    if (_loginComplete)
    {
        if(_loginStatus.intValue == UMRpcError_NO_ERROR)
        {
            return YES;
        }
    }
    return NO;
}

- (BOOL)connect
{
    if(_socket.isConnected==NO)
    {
        UMSocketError err = [_socket connect];
        if(err==UMSocketError_no_error)
        {
            _handler  = [[UMRpcHandler alloc]initWithSocket:_socket
                                                     client:self
                                                    logFeed:_logFeed
                                                   logLevel:_logLevel];
            _session = _handler.session;
            [_handler startBackgroundTask];
        }
        else
        {
            NSString *s = [NSString stringWithFormat:@"connect() failed with err=%@",[UMSocket getSocketErrorString:err]];
            [_logFeed majorErrorText:s];
        }
    }
    return _socket.isConnected;
}


- (BOOL) awaitsResponses
{
    return [_session awaitsResponses];
}

- (NSNumber *) synchronousLogin
{
    if(_session==NULL)
    {
        return @(UMRpcError_NOT_CONNECTED);
    }

    _loginComplete      = NO;
    _loginStatus        = NULL;
    UMSocketError e     = [_session doLogin:_username
                                   password:_password
                                   instance:_instance
                     onCompletionCallObject:self
                               withSelector:@selector(loginResponse:session:)];
    if(e!=UMSocketError_no_error)
    {
        return @(UMRpcError_CONNECTION_ERROR);
    }
    while(_loginComplete==NO)
    {
        usleep(1000);
    }
    return _loginStatus;
}

- (NSNumber *)loginResponse:(UMRpcMessage_LoginResponse *)cmd
              session:(UMRpcSession *)session
{
    _loginStatus = cmd.status;
    _loginComplete = YES;
    if(_loginStatus.intValue == UMRpcError_NO_ERROR)
    {
        [session startHeartbeat];
        return @(0);
    }
    return _loginStatus;

}

- (NSNumber *) synchronousLogout:(NSString *)reason
{
    if(_session==NULL)
    {
        return @(UMRpcError_NOT_CONNECTED);
    }
    _logoutComplete = NO;
    _logoutStatus   = NULL;
    UMSocketError  e = [_session doLogout:reason
                   onCompletionCallObject:self
                             withSelector:@selector(logoutResponse:session:)];

    if(e!=UMSocketError_no_error)
    {
        return @(UMRpcError_CONNECTION_ERROR);
    }
    while(_logoutComplete==NO)
    {
        usleep(1000);
    }
    return _logoutStatus;
}

- (void)logoutResponse:(UMRpcMessage *)cmd
              session:(UMRpcSession *)session
{
    UMRpcMessage_LogoutResponse *msg = [[UMRpcMessage_LogoutResponse alloc]initWithASN1Object:cmd context:NULL];
    [session stopHeartbeat];
    [self close];
    _logoutStatus = msg.status;
    _logoutComplete = YES;
}



- (void)close
{
    [_handler shutdownBackgroundTask];
    [_handler.session.socket close];
    _handler.session = NULL;
    _session = NULL;
    _handler = NULL;
}


- (UMSocketError)processRequest:(UMRpcMessage *)msg
                        session:(UMRpcSession *)session
{
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
                msg.callbackObject = sh.objectToAdd;
                n = [sh.objectToCall performSelector:sh.selectorToCall withObject:msg withObject:_session];
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


@end
