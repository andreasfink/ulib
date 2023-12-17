//
//  UMHTTPRequest.h
//  UniversalHTTP
//
//  Created by Andreas Fink on 30.12.08.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//


#import "UMObject.h"
#import "UMHTTPResponseCode.h"
#import "UMHTTPAuthenticationStatus.h"
#import "UMMutex.h"

#define DEFAULT_UMHTTP_SERVER_TIMEOUT       90.0

@class UMHTTPRequest;
@protocol UMHTTPRequest_TimeoutProtocol<NSObject>
- (void) httpRequestTimeout:(UMHTTPRequest *)req;
@end

@class UMHTTPConnection;
@class UMSleeper;
@class UMHTTPCookie;


/*!
 @class UMHTTPRequest
 @brief  UMHTTPRequest represents a single http page request.

 A UMHTTPRequest is passed to a delegate of a UMHTTPServer.
 params is filled with the params passed on the URL (get) or in the body (post)
 */

@interface UMHTTPRequest : UMObject
{
    uint64_t            _requestId;
    NSDate              *_completionTimeout;
    BOOL                _awaitingCompletion; /* set to YES if data is returned later */

	UMHTTPConnection	*_connection; /* we own the connection while processing it */
	NSString			*_method; /* GET/POST etc */
	NSString			*_protocolVersion;
    NSString			*_connectionValue;
	NSString			*_path;
	NSURL				*_url;
	NSMutableDictionary	*_requestHeaders;
	NSMutableDictionary	*_responseHeaders;
	NSData				*_requestData;
	NSData				*_responseData;
	NSDictionary		*_params;
	UMHTTPResponseCode	_responseCode;
    UMHTTPAuthenticationStatus _authenticationStatus;
    UMSleeper           *_sleeper;  /* wake up this sleeper once data is returned by calling resumePendingRequest */
    NSMutableDictionary *_requestCookies;
    NSMutableDictionary *_responseCookies;
    NSString            *_authUsername;
    NSString            *_authPassword;
    
    id<UMHTTPRequest_TimeoutProtocol>    _timeoutDelegate;
    BOOL                _mustClose; /* if set, it means after answering this request the connection shall close */
    UMMutex             *_pendingRequestLock;
    NSString            *_documentRoot;
    BOOL                _isWebSocketRequest;
    
    NSString            *_remoteAddress;
    int                 _remotePort;

}

@property (readwrite,assign,atomic)uint64_t            requestId;
@property (readwrite,strong,atomic)NSDate               *completionTimeout;
@property (readwrite,assign,atomic) BOOL                awaitingCompletion;

@property (readwrite,strong,atomic) UMHTTPConnection	*connection;
//@property (readonly,assign) CFHTTPMessageRef			request;
//@property (readonly,assign) CFHTTPMessageRef			response;
@property (readwrite,strong) NSString					*protocolVersion;
@property (readwrite,strong) NSString					*connectionValue;
@property (readwrite,strong) NSString					*method;
@property (readwrite,strong) NSString					*path;
@property (readwrite,strong) NSURL						*url;
@property (readwrite,strong) NSMutableDictionary		*requestHeaders;
@property (readwrite,strong) NSMutableDictionary        *responseHeaders;
@property (readwrite,strong) NSData						*requestData;
@property (readwrite,strong) NSData						*responseData;
@property (readwrite,assign) UMHTTPResponseCode			responseCode;
@property (readwrite,assign) UMHTTPAuthenticationStatus authenticationStatus;
@property (readwrite,strong) NSMutableDictionary        *requestCookies;
@property (readwrite,strong) NSMutableDictionary		*responseCookies;
@property (readwrite,strong) NSDictionary               *params;
@property (readwrite,strong,atomic) id<UMHTTPRequest_TimeoutProtocol>    timeoutDelegate;
@property (readwrite,strong) NSString                   *authUsername;
@property (readwrite,strong) NSString                   *authPassword;
@property (readwrite,assign,atomic)     BOOL            mustClose;
@property (readwrite,strong) NSString                   *documentRoot;
@property (readwrite,assign) BOOL                       isWebSocketRequest;
@property (readwrite,strong) NSString                   *remoteAddress;
@property (readwrite,assign) int                        remotePort;


- (NSString *)name;
//- (id) initWithRequest:(CFHTTPMessageRef)req connection:(UMHTTPConnection *)conn;
- (id) init;
- (UMHTTPConnection *) connection;
//- (void) setResponse:(CFHTTPMessageRef)value;
- (void) setNotFound;
- (void) setRequireAuthentication;
- (void) extractGetParams;
- (void) extractPutParams;
- (void) extractPostParams;
- (void) extractParams:(NSString *)query;
- (NSString *)responseCodeAsString;
- (void) setRequestHeader:(NSString *)s withValue:(NSString *)value;
- (void) setRequestHeadersFromArray:(NSMutableArray *)array;
- (void) removeRequestHeader:(NSString *)s;
- (void) setResponseHeader:(NSString *)s withValue:(NSString *)value;
- (NSData *)extractResponseHeader;
- (NSData *)extractResponse;
- (void) setResponsePlainText:(NSString *)content;
- (void) appendResponsePlainText:(NSString *)content;

- (void) setResponseHtmlString:(NSString *)content;
- (void) setResponseCssString:(NSString *)content;
- (void) setResponseJsonString:(NSString *)content;
- (void) setResponseJsonObject:(id)content;
- (void)setNotAuthorizedForRealm:(NSString *)realm; /* depreciated */
- (void)setNotAuthorisedForRealm:(NSString *)realm;
- (void)setContentType:(NSString *)ct;
- (NSString *)authenticationStatusAsString;
- (NSMutableDictionary *)paramsMutableCopy;
- (void)setResponseTypeText;
- (void)setResponseTypeHtml;
- (void)setResponseTypeCss;
- (void)setResponseTypePng;
- (void)setResponseTypeJpeg;
- (void)setResponseTypeGif;
- (void)setResponseTypeJson;
- (void)setResponseTypeBinary;
- (void)setResponseTypeJavascript;

- (void)setCookie:(NSString *)cookieName withValue:(NSString *)value;
- (void)setCookie:(NSString *)cookieName withValue:(NSString *)value forPath:(NSString *)path;
- (void)setCookie:(NSString *)cookieName withValue:(NSString *)value forPath:(NSString *)p expires:(NSDate *)expDate;
- (UMHTTPCookie *)getCookie:(NSString *)name;
- (void)makeAsync;
- (void)makeAsyncWithTimeout:(NSTimeInterval)timeoutInSeconds;
- (void)makeAsyncWithTimeout:(NSTimeInterval)timeoutInSeconds delegate:(id<UMHTTPRequest_TimeoutProtocol>)callback;
- (void)resumePendingRequest;
- (void)sleepUntilCompleted;
- (void)redirect:(NSString *)newPath;
- (void)setRequestCookie:(UMHTTPCookie *)cookie;
- (void)setResponseCookie:(UMHTTPCookie *)cookie;
- (void)finishRequest;

- (void)setMimeTypeFromExtension:(NSString *)extension;
@end
