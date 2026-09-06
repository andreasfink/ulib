//
//  UMRpcSession.h
//  ulibrpc
//
//  Created by Andreas Fink on 20.08.2026.
//

#import <ulib/UMASN1Sequence.h>
#import <ulib/UMRpcError.h>
#import <ulib/UMTimer.h>
#import <ulib/UMSynchronizedDictionary.h>
#import <ulib/UMSocket.h>
#import <ulib/UMLogFeed.h>
#import <ulib/UMLogLevel.h>
#import <ulib/UMUtil.h>
#import <ulib/UMAssert.h>

@class UMRpcServer;
@class UMRpcClient;
@class UMRpcHandler;
@class UMRpcMessage;
@class UMRpcSessionHandler;
@class UMRpcMessageDecoder;

@interface UMRpcSession : UMObject

{
    UMSocket            *_socket;
    UMRpcServer         *_server;
    UMRpcClient         *_client;
    UMRpcHandler        *_handler;
    NSString            *_instance;
    BOOL                _authenticated;
    NSString            *_username;
    NSString            *_password;
    NSDate              *_lastHandshakeRequested;
    NSDate              *_lastHandshakeResponse;
    NSDate              *_lastHandshakeReceived;
    UMTimer             *_handshakeTimer;
    UMMutex             *_lock;
    NSInteger           _lastSequenceNumber;
    NSString            *_clientName;
    NSInteger           _clientApiVersion;
    NSInteger           _serverApiVersion;
    BOOL                _clientSuccessfullyLoggedIn;
    UMLogLevel          _logLevel;
    UMSynchronizedDictionary *_pendingSequences; /* dictionary key=NSNumber(SequenceNumber) value:UMRpcSessionHandler */
    UMRpcMessageDecoder *_messageDecoder;
}

@property(readwrite,strong,atomic)  UMSocket        *socket;
@property(readwrite,strong,atomic)  UMRpcServer     *server;
@property(readwrite,strong,atomic)  UMRpcClient     *client;
@property(readwrite,strong,atomic)  UMRpcHandler    *handler;
@property(readwrite,strong,atomic)  NSString        *instance;
@property(readwrite,assign,atomic)  BOOL            authenticated;
@property(readwrite,strong,atomic)  NSString        *username;
@property(readwrite,strong,atomic)  NSString        *password;
@property(readwrite,strong,atomic)  NSDate          *lastHandshakeRequested;
@property(readwrite,strong,atomic)  NSDate          *lastHandshakeResponse;
@property(readwrite,strong,atomic)  NSDate          *lastHandshakeReceived;
@property(readwrite,strong,atomic)  NSString        *clientName;
@property(readwrite,strong,atomic)  NSString        *serverName;
@property(readwrite,assign,atomic)  NSInteger        clientApiVersion;
@property(readwrite,assign,atomic)  NSInteger        serverApiVersion;
@property(readwrite,assign,atomic)  BOOL             cclientSuccessfullyLoggedIn;
@property(readwrite,assign,atomic)  UMLogLevel       logLevel;
@property(readwrite,strong,atomic)  UMRpcMessageDecoder *messageDecoder;

- (UMSocketError)sendMessage:(UMRpcMessage *)msg; /* return error code*/
- (UMSocketError)processMessage:(UMRpcMessage *)cmd; /* return error code*/
- (BOOL) awaitsResponses;
- (UMSocketError) doLogin:(NSString *)username
                 password:(NSString *)password
                 instance:(NSString *)instance
   onCompletionCallObject:(id)obj
             withSelector:(SEL)sel;

- (UMSocketError) doLogout:(NSString *)reason
    onCompletionCallObject:(id)obj
              withSelector:(SEL)sel;

- (UMSocketError)submitMessage:(UMRpcMessage *)msg
                   withHandler:(UMRpcSessionHandler*)handler;

- (UMSocketError) submitMessage:(UMRpcMessage *)msg
         onCompletionCallObject:(id)obj
                   withSelector:(SEL)sel;

- (UMSocketError) submitMessage:(UMRpcMessage *)msg
         onCompletionCallObject:(id)obj
                   withSelector:(SEL)sel
                     andObject2:(id)obj2;

- (void) startHeartbeat;
- (void) stopHeartbeat;

@end

