//
//  UMRpcServer.h
//  ulibrpc
//
//  Created by Andreas Fink on 20.08.2026.
//

#import <ulibasn1/UMASN1Sequence.h>
#import <ulibasn1/UMRpcError.h>
#import <ulibasn1/UMRpcServer_AuthenticateProtocol.h>


@class UMRpcSession;
@class UMRpcMessage;
@class UMRpcSessionHandler;
@class UMRpcMessageDecoder;

@interface UMRpcServer : UMBackgrounder
{
    UMTaskQueue                             *_taskQueue;
    UMSynchronizedSortedDictionary          *_commandHandlers;
    UMSynchronizedSortedDictionary          *_messageTypes;
    NSInteger                               _port;
    UMSocket                                *_listener;
    UMSynchronizedArray                     *_incomingConnections; /* array of UMRcpHandler objects */
    UMLogLevel                              _logLevel;
    id <UMRpcServer_AuthenticateProtocol>   _authenticationDelegate;
    UMRpcMessageDecoder                     *_messageDecoder;
}

@property(readwrite,strong,atomic) UMTaskQueue                *taskQueue;
@property(readwrite,assign,atomic) NSInteger                   port;
@property(readwrite,strong,atomic) UMSocket                    *listener;
@property(readwrite,strong,atomic) UMSynchronizedArray         *incomingConnections;
@property(readwrite,assign,atomic) UMLogLevel                  logLevel;
@property(readwrite,strong,atomic) id<UMRpcServer_AuthenticateProtocol> authenticationDelegate;
@property(readwrite,strong,atomic) UMRpcMessageDecoder          *messageDecoder;

- (NSString *)messageTypeName:(NSNumber *)n;

- (UMRpcServer *)initWithName:(NSString *)name
                         port:(NSInteger)port
                      logFeed:(UMLogFeed *)feed
                     logLevel:(UMLogLevel)level;

- (void)addCommand:(NSInteger)commandId name:(NSString *)name
      objectToCall:(id)obj
          selector:(SEL)selector;

- (UMSocketError)processRequest:(UMRpcMessage *)msg   session:(UMRpcSession *)session;
- (UMSocketError)processResponse:(UMRpcMessage *)msg  session:(UMRpcSession *)session sessionHandler:(UMRpcSessionHandler *)sh;


@end

