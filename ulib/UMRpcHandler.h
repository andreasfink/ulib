//
//  UMRpcHandler.h
//  ulibrpc
//
//  Created by Andreas Fink on 20.08.2026.
//

#import <ulib/UMASN1Sequence.h>
#import <ulib/UMBackgrounder.h>
#import <ulib/UMSocket.h>
#import <ulib/UMLogLevel.h>

@class UMRpcSession;
@class UMRpcServer;
@class UMRpcClient;
@class UMRpcMessageDecoder;

@interface UMRpcHandler : UMBackgrounder
{
    UMSocket *              _socket;
    int                     _maxReceiveBuffer;
    UMRpcSession            *_session;
    UMRpcServer             *_server;
    UMRpcClient             *_client;
    UMLogLevel              _logLevel;
    UMRpcMessageDecoder     *_messageDecoder;
}


@property(readwrite,strong,atomic)  id   commandHandlerDelegate;
@property(readwrite,strong,atomic)  UMRpcSession *session;
@property(readwrite,assign,atomic)  UMLogLevel  logLevel;
@property(readwrite,strong,atomic)  UMRpcMessageDecoder     *messageDecoder;

- (UMRpcHandler *)initWithSocket:(UMSocket *)s
                          server:(UMRpcServer *)server
                         logFeed:(UMLogFeed *)feed
                        logLevel:(UMLogLevel)level;

- (UMRpcHandler *)initWithSocket:(UMSocket *)s
                          client:(UMRpcClient *)client
                         logFeed:(UMLogFeed *)feed
                        logLevel:(UMLogLevel)level;


@end
