//
//  UMRpcClient.h
//  ulibrpc
//
//  Created by Andreas Fink on 20.08.2026.
//

#import <ulib/UMASN1Sequence.h>
#import <ulib/UMRpcError.h>
#import <ulib/UMRpcMessage.h>
#import <ulib/UMRpcSessionHandler.h>
#import <ulib/UMSocket.h>
#import <ulib/UMLogLevel.h>
#import <ulib/UMLogFeed.h>

@class UMRpcHandler;
@class UMRpcSession;
@class UMRpcMessageDecoder;

@interface UMRpcClient : UMObject
{
    UMSocket                    *_socket;
    UMRpcSession                *_session;
    UMRpcHandler                *_handler;
    NSString                    *_username;
    NSString                    *_password;
    NSString                    *_instance;
    BOOL                        _loginComplete;
    NSNumber                    *_loginStatus;
    BOOL                        _logoutComplete;
    NSNumber                    *_logoutStatus;
    UMLogLevel                  _logLevel;
    UMSynchronizedSortedDictionary  *_messageTypes;
    UMRpcMessageDecoder         *_messageDecoder;
}

@property(readwrite,strong) UMSocket                    *socket;
@property(readwrite,strong) UMRpcSession                *session;
@property(readwrite,strong) UMRpcHandler                *handler;
@property(readwrite,strong) NSString                    *username;
@property(readwrite,strong) NSString                    *password;
@property(readwrite,strong) NSString                    *instance;
@property(readwrite,assign) BOOL                        loginComplete;
@property(readwrite,strong) NSNumber                    *loginStatus;
@property(readwrite,assign) UMLogLevel                  logLevel;
@property(readwrite,strong) UMRpcMessageDecoder         *messageDecoder;

- (UMRpcClient *)initWithHost:(UMHost *)host port:(int)port;
- (void)addMessageType:(NSInteger)commandId name:(NSString *)name;
- (NSString *)messageTypeName:(NSNumber *)n;
- (BOOL)isConnected;
- (BOOL)isLoggedIn;
- (BOOL)connect;
- (BOOL) awaitsResponses;
- (NSNumber *)synchronousLogin;
- (NSNumber *)synchronousLogout:(NSString *)reason;
- (void)close;

- (UMSocketError)processRequest:(UMRpcMessage *)msg   session:(UMRpcSession *)session;
- (UMSocketError)processResponse:(UMRpcMessage *)msg  session:(UMRpcSession *)session sessionHandler:(UMRpcSessionHandler *)sh;

@end
