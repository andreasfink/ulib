//
//  UMHTTPConnection.h
//  UniversalHTTP
//
//  Created by Andreas Fink on 30.12.08.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMObject.h>
#import <ulib/UMHTTPWebSocketDelegateProtocol.h>

@class UMHTTPServer;
@class UMHTTPRequest;
@class UMSocket;

#define	DEFAULT_HTTP_TIMEOUT	120

typedef enum UMHTTPConnectionRequestSection
{
    UMHTTPConnectionRequestSectionFirstLine,
    UMHTTPConnectionRequestSectionHeaderLine,
    UMHTTPConnectionRequestSectionData,
    UMHTTPConnectionRequestSectionErrorOrClose,
} UMHTTPConnectionRequestSection;

// This class represents each incoming client connection.
@interface UMHTTPConnection : UMObject
{
    NSString        *_name;
	int				_timeout;
@private
	UMHTTPServer 	*_server;
	UMSocket		*_socket;
    BOOL            _mustClose;
    BOOL            _inputClosed;
	NSDate			*_lastActivity;

	UMHTTPConnectionRequestSection				cSection;
	ssize_t			_awaitingBytes;
    BOOL            _enableKeepalive;
    UMHTTPRequest    *_currentRequest;
    BOOL            _inWebSocketMode;
    NSString        *_webSocketKeyString;
    NSData          *_webSocketKey;
    NSString        *_webSocketProtocol;
    NSString        *_webSocketVersion;
    NSString        *_webSocketOrigin;
    NSString        *_webSocketKeyResponseString;
    id<UMHTTPWebSocketDelegateProtocol> _httpWebSocketDelegate;
}

@property(readwrite,strong,atomic)  NSString        *name;
@property (readwrite,strong,atomic) UMHTTPServer	*server;
@property (readonly,strong,atomic)  UMSocket		*socket;
@property (readwrite,assign,atomic) BOOL            mustClose;
@property (readwrite,assign,atomic) BOOL            inputClosed;
@property (readwrite,assign,atomic) int				timeout;
@property (readwrite,strong,atomic) NSDate			*lastActivity;
@property (readwrite,strong,atomic) UMHTTPRequest	*currentRequest;
@property (readwrite,assign,atomic) BOOL            enableKeepalive;
@property (readwrite,assign,atomic) BOOL            inWebSocketMode;
@property(readwrite, strong,atomic) id <UMHTTPWebSocketDelegateProtocol> httpWebSocketDelegate;
@property (readwrite,strong,atomic) NSString        *webSocketKeyString;
@property (readwrite,strong,atomic) NSData          *webSocketKey;
@property (readwrite,strong,atomic) NSString        *webSocketProtocol;
@property (readwrite,strong,atomic) NSString        *webSocketVersion;
@property (readwrite,strong,atomic) NSString        *webSocketOrigin;
@property (readwrite,strong,atomic) NSString        *webSocketKeyResponseString;

- (UMHTTPConnection *) initWithSocket:(UMSocket *)socket server:(UMHTTPServer *)server;
- (NSString *)description;
- (void) connectionListener;
- (int) checkForIncomingData:(NSMutableData *)appendToMe requestCompleted:(BOOL *)complete;
- (void) processHTTPRequest:(UMHTTPRequest *)request;
- (void) terminateForServer;
//- (void) addLogFromConfigFile:(NSString *)file withSection:(NSString *)section withSubsection:(NSString *)subsection withName:(NSString *)name;

@end
