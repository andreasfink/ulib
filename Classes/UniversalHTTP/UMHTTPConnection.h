//
//  UMHTTPConnection.h
//  UniversalHTTP
//
//  Created by Andreas Fink on 30.12.08.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"

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
	int				timeout;
@private
	UMHTTPServer	*server;
	UMSocket		*socket;
    BOOL            _mustClose;
    BOOL            _inputClosed;
	NSDate			*lastActivity;

	UMHTTPConnectionRequestSection				cSection;
	ssize_t			awaitingBytes;
    BOOL            _enableKeepalive;
}

@property(readwrite,strong,atomic)     NSString        *name;
@property (readonly,strong)		UMHTTPServer	*server;
@property (readonly,strong)		UMSocket		*socket;
@property (readwrite,assign,atomic)    BOOL            mustClose;
@property (readwrite,assign,atomic)    BOOL            inputClosed;
@property (readwrite,assign)	int				timeout;
@property (readwrite,strong)	NSDate			*lastActivity;
@property (readwrite,strong,atomic)    UMHTTPRequest	*currentRequest;
@property (readwrite,assign,atomic)    BOOL            enableKeepalive;


- (UMHTTPConnection *) initWithSocket:(UMSocket *)socket server:(UMHTTPServer *)server;
- (NSString *)description;
- (void) connectionListener;
- (int) checkForIncomingData:(NSMutableData *)appendToMe requestCompleted:(BOOL *)complete;
- (void) processHTTPRequest:(UMHTTPRequest *)request;
- (void) terminate;
//- (void) addLogFromConfigFile:(NSString *)file withSection:(NSString *)section withSubsection:(NSString *)subsection withName:(NSString *)name;

@end
