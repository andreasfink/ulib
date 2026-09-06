//
//  UMRpcSession.m
//  ulibrpc
//
//  Created by Andreas Fink on 20.08.2026.
//

#import "UMRpcSession.h"


#import <ulib/UMRpcSession.h>
#import <ulib/UMRpcServer.h>
#import <ulib/UMRpcClient.h>
#import <ulib/UMRpcHandler.h>
#import <ulib/UMRpcMessage.h>
#import <ulib/UMRpcError.h>
#import <ulib/UMRpcMessage_HeartbeatRequest.h>
#import <ulib/UMRpcMessage_HeartbeatResponse.h>
#import <ulib/UMRpcMessage_LoginRequest.h>
#import <ulib/UMRpcMessage_LoginResponse.h>
#import <ulib/UMRpcMessage_LogoutRequest.h>
#import <ulib/UMRpcMessage_LogoutResponse.h>
#import <ulib/UMRpcMessage_TestRequest.h>
#import <ulib/UMRpcMessage_TestResponse.h>
#import <ulib/UMRpcMessage_GenericError.h>
#import <ulib/UMRpcSessionHandler.h>
#import <ulib/UMRpcMessageType.h>
#import <ulib/UMRpcFlag.h>
#import <ulib/UMRpcMessageDecoder.h>

@implementation UMRpcSession

- (UMRpcSession *)init
{
    self = [super init];
    if(self)
    {
        _lastSequenceNumber = 0;
        _lock = [[UMMutex alloc]initWithName:@"umrpc-session"];
        _handshakeTimer = [[UMTimer alloc]initWithTarget:self
                                                selector:@selector(doHandshake)
                                                  object:NULL
                                                 seconds:10
                                                    name:NULL
                                                 repeats:YES
                                         runInForeground:YES];
        _serverApiVersion = 1;
        _clientApiVersion = 1;
        _clientName = @"umrpcclient";
        _pendingSequences = [[UMSynchronizedDictionary alloc]init];
        _username = @"testuser";
        _password = @"testpass";
    }
    return self;
}

- (NSNumber *)getSequenceNumber
{
    NSInteger i;
    ummutex_lock(_lock);
    i = _lastSequenceNumber+1;
    if(i > 0x7FFF)
    {
        i=1;
    }
    _lastSequenceNumber = i;
    ummutex_unlock(_lock);
    return @(i);
}

- (void)doHandshake
{
    UMRpcMessage_HeartbeatRequest *req = [[UMRpcMessage_HeartbeatRequest alloc]init];
    req.sequenceNumber = [self getSequenceNumber];
    [self sendMessage:req];
    _lastHandshakeRequested = [NSDate date];
}

- (int)processGenericError:(UMRpcMessage_GenericError *)cmd
{
    NSString *s = [NSString stringWithFormat:@"%@",cmd.objectValue];
    fprintf(stderr,"GENERIC_ERROR %s",s.UTF8String);
    return cmd.status.intValue;
}

- (int)processHeartbeatRequest:(UMRpcMessage_HeartbeatRequest *)cmd
{
    UMRpcMessage_HeartbeatResponse *res = [[UMRpcMessage_HeartbeatResponse alloc]init];
    [res setFlag:UMRpcFlag_IS_RESPONSE];
    res.sequenceNumber = cmd.sequenceNumber;
    UMSocketError err;
    err = [self sendMessage:res];
    if(err != UMSocketError_no_error)
    {
        return -1;
    }
    return 0;
}

- (int)processHeartbeatResponse:(UMRpcMessage_HeartbeatResponse *)cmd
{
    _lastHandshakeReceived = [NSDate date];
    return 0;
}


/* this login is the system logging into the billing server */
- (int)processLoginRequest:(UMRpcMessage_LoginRequest *)cmd
{
    UMRpcError error = [_server.authenticationDelegate  login:cmd.username
                                                     password:cmd.password
                                                         host:_socket.connectedRemoteAddress
                                                     instance:cmd.instance
                                                    session:self];
    UMRpcMessage_LoginResponse *res = [[UMRpcMessage_LoginResponse alloc]init];
    if(error ==UMRpcError_NO_ERROR)
    {
        _authenticated = YES;
        _instance = cmd.instance;
    }
    else
    {
        [res setFlag:UMRpcFlag_CLOSING_CONNECTION];
    }
    res.status = @(error);
    res.sequenceNumber = cmd.sequenceNumber;
    res.serverApiVersion = @(_serverApiVersion);
    res.serverName = _server.name;
;
    UMSocketError err = [self sendMessage:res];
    if(err != UMSocketError_no_error)
    {
        return -1;
    }
    if(_authenticated)
    {
        return 0;
    }
    else
    {
        return -2;
    }
}

- (int)processLoginResponse:(UMRpcMessage_LoginResponse *)cmd
{
    if(cmd.serverName)
    {
        _serverName = cmd.serverName;
    }
    _serverApiVersion = cmd.serverApiVersion.intValue;
    if(cmd.status == UMRpcError_NO_ERROR)
    {
        _clientSuccessfullyLoggedIn = YES;
    }
    else
    {
        _clientSuccessfullyLoggedIn = NO;
    }
    return [self processResponse:cmd];
}


- (UMSocketError)processResponse:(UMRpcMessage *)msg
{
    NSNumber *seq = msg.sequenceNumber;
    UMRpcSessionHandler *sh = _pendingSequences[seq];
    if(sh)
    {
        if(_server)
        {
            return [_server processResponse:msg session:self sessionHandler:sh];
        }
        if(_client)
        {
            return [_client processResponse:msg session:self sessionHandler:sh];
        }
    }
    return UMSocketError_no_error;
}

- (int)processLogoutRequest:(UMRpcMessage_LogoutRequest *)cmd
{
    UMRpcMessage_LogoutResponse *res = [[UMRpcMessage_LogoutResponse alloc]init];
    res.status = @(0);
    res.sequenceNumber = cmd.sequenceNumber;
    [res setFlag:UMRpcFlag_CLOSING_CONNECTION];
    UMSocketError err = [self sendMessage:res];
    if(err != UMSocketError_no_error)
    {
        return err;
    }
    return UMSocketError_connection_reset;
}

- (int)processLogoutResponse:(UMRpcMessage_LogoutResponse *)cmd
{
    return UMSocketError_connection_reset;
}

- (void)debugLogMessage:(UMRpcMessage *)msg type:(NSString *)cmdName
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        NSString *s = [NSString stringWithFormat:@"Received %@\n%@",cmdName,msg.objectValue.jsonString];
        [_logFeed debugText:s];
    }
}

- (UMSocketError)processMessage:(UMRpcMessage *)msg1 /* return error code*/
{
    UMRpcMessage *msg;
    if(_messageDecoder)
    {
        msg = [_messageDecoder decodeMessage:msg1];
    }
    else
    {
        msg = msg1;
    }
    NSString *cmdName = NULL;
    if(_logLevel <=UMLOG_DEBUG)
    {
        if(_server)
        {
            cmdName = [_server messageTypeName:msg.command];
            [self debugLogMessage:msg type:cmdName];
        }
        else if(_client)
        {
            cmdName = [_client messageTypeName:msg.command];
            [self debugLogMessage:msg type:cmdName];
        }
    }

    switch(msg.command.intValue)
    {
        case UMRpcMessageType_GENERIC_ERROR:
        {
            return [self processGenericError:(UMRpcMessage_GenericError *)msg];
        }
        case UMRpcMessageType_HEARTBEAT_REQUEST:
        {
            return [self processHeartbeatRequest:(UMRpcMessage_HeartbeatRequest *)msg];
        }
        case UMRpcMessageType_HEARTBEAT_RESPONSE:
        {
            return [self processHeartbeatResponse:(UMRpcMessage_HeartbeatResponse *)msg];
        }
        case UMRpcMessageType_LOGIN_REQUEST:
        {
            return [self processLoginRequest:(UMRpcMessage_LoginRequest *)msg];
        }
        case UMRpcMessageType_LOGIN_RESPONSE:
        {
            return [self processLoginResponse:(UMRpcMessage_LoginResponse *)msg];
        }
        case UMRpcMessageType_LOGOUT_REQUEST:
        {
            return [self processLogoutRequest:(UMRpcMessage_LogoutRequest *)msg];
        }
        case UMRpcMessageType_LOGOUT_RESPONSE:
        {
            return [self processLogoutResponse:(UMRpcMessage_LogoutResponse *)msg];
        }
        default:
            /* everything else is processed below , including TEST_REQUEST and TEST_RESPONSE */
            break;
    }

    if([msg isFlagSet:UMRpcFlag_IS_RESPONSE])
    {
        return [self processResponse:msg];
    }
    else
    {
        if(_server)
        {
            return [_server processRequest:msg  session:self];
        }
        if(_client)
        {
            return [_client processRequest:msg  session:self];
        }
    }
    return UMSocketError_generic_error;
}

- (UMSocketError)sendMessage:(UMRpcMessage *)cmd
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        if(_server)
        {
            NSString *cmdName = [_server messageTypeName:cmd.command];
            NSString *s = [NSString stringWithFormat:@"Server Sending %@\n%@",cmdName,cmd.objectValue.jsonString];
            [_logFeed debugText:s];
        }
        else if(_client)
        {
            NSString *cmdName = [_client messageTypeName:cmd.command];
            NSString *s = [NSString stringWithFormat:@"Client Sending %@\n%@",cmdName,cmd.objectValue.jsonString];
            [_logFeed debugText:s];
        }
        else
        {
            NSString *s = [NSString stringWithFormat:@"not client/not server: Sending %@",cmd.objectValue.jsonString];
            [_logFeed majorErrorText:s];
        }
    }
    NSData *data = [cmd berEncoded];
    UMSocketError err = [_socket sendData:data];
    int count=0;
    while((err==UMSocketError_try_again) && (count++ < 10))
    {
        usleep(100);
        err = [_socket sendData:data];
    }
    return err;
}

- (BOOL) awaitsResponses
{
    if(_pendingSequences.count > 0)
    {
        return YES;
    }
    return NO;
}


- (UMSocketError) submitMessage:(UMRpcMessage *)msg
         onCompletionCallObject:(id)obj
                   withSelector:(SEL)sel
{
    if((obj) && (sel))
    {
        if(![obj respondsToSelector:sel])
        {
            UMAssert(0,@"Object does not respond to selector");
        }
    }
    UMRpcSessionHandler *sh = [[UMRpcSessionHandler alloc]init];
    sh.objectToCall = obj;
    sh.selectorToCall = sel;
    sh.objectToAdd    = NULL;
    return [self submitMessage:msg withHandler:sh];
}


- (UMSocketError) submitMessage:(UMRpcMessage *)msg
         onCompletionCallObject:(id)obj
                   withSelector:(SEL)sel
                     andObject2:(id)obj2
{
    if((obj) && (sel))
    {
        if(![obj respondsToSelector:sel])
        {
            UMAssert(0,@"Object does not respond to selector");
        }
    }
    UMRpcSessionHandler *sh = [[UMRpcSessionHandler alloc]init];
    sh.objectToCall = obj;
    sh.selectorToCall = sel;
    sh.objectToAdd    = obj2;
    return [self submitMessage:msg withHandler:sh];
}

- (UMSocketError) doLogin:(NSString *)username
                 password:(NSString *)password
                 instance:(NSString *)instance
   onCompletionCallObject:(id)obj
             withSelector:(SEL)sel
{
    if((obj) && (sel))
    {
        if(![obj respondsToSelector:sel])
        {
            UMAssert(0,@"Object does not respond to selector");
        }
    }
    UMRpcSessionHandler *hdl = [[UMRpcSessionHandler alloc]init];
    hdl.objectToCall = obj;
    hdl.selectorToCall = sel;
    hdl.objectToAdd    = NULL;
    
    UMRpcMessage_LoginRequest *req = [[UMRpcMessage_LoginRequest alloc]init];
    req.username = username;
    req.password = password;
    req.instance = instance;
    req.apiVersion = @(1);
    return [self submitMessage:req withHandler:hdl];
}

- (UMSocketError) doLogout:(NSString *)reason
    onCompletionCallObject:(id)obj
              withSelector:(SEL)sel
{
    if((obj) && (sel))
    {
        if(![obj respondsToSelector:sel])
        {
            UMAssert(0,@"Object does not respond to selector");
        }
    }
    UMRpcSessionHandler *hdl = [[UMRpcSessionHandler alloc]init];
    hdl.objectToCall = obj;
    hdl.selectorToCall = sel;
    hdl.objectToAdd    = NULL;
    
    UMRpcMessage_LogoutRequest *req = [[UMRpcMessage_LogoutRequest alloc]init];
    req.reason = reason;
    return [self submitMessage:req withHandler:hdl];
}

- (UMSocketError)submitMessage:(UMRpcMessage *)msg
                   withHandler:(UMRpcSessionHandler*)handler
{
    NSNumber *seq = [self getSequenceNumber];
    msg.sequenceNumber = seq;
    _pendingSequences[seq] = handler;
    UMSocketError err = [self sendMessage:msg];
    if(err != UMSocketError_no_error)
    {
        [_pendingSequences removeObjectForKey:seq];
        return err;
    }
    return UMSocketError_no_error;
}

- (void)startHeartbeat
{
    [_handshakeTimer start];
}

- (void)stopHeartbeat
{
    [_handshakeTimer stop];
}


@end
