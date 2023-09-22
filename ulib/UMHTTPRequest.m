//
//  UMHTTPRequest.m
//  UniversalHTTP
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMHTTPRequest.h>
#import <ulib/UMHTTPConnection.h>
#import <ulib/UMHTTPServer.h>
#import <ulib/UMSocket.h>
#import <ulib/NSMutableArray+UMHTTP.h>
#import <ulib/NSMutableString+UMHTTP.h>
#import <ulib/NSString+UMHTTP.h>
#import <ulib/UMSleeper.h>
#import <ulib/UMHTTPCookie.h>
#import <ulib/UMJsonWriter.h>
#import <ulib/UMHTTPTask_ReadRequest.h>
#import <ulib/UMTaskQueue.h>
#import <ulib/UMSynchronizedArray.h>
#import <ulib/NSString+UniversalObject.h>

@implementation UMHTTPRequest

- (id) init
{
    static uint64_t lastRequestId = 0;
    static UMMutex *lastRequestId_lock;

    if(lastRequestId_lock==NULL)
    {
        lastRequestId_lock = [[UMMutex alloc]initWithName: @"last-requested-id"];
    }

    self = [super init];
    if(self)
	{
        UMMUTEX_LOCK(lastRequestId_lock);
        _requestId = ++lastRequestId;
        _completionTimeout = [NSDate dateWithTimeIntervalSinceNow:120];
        UMMUTEX_UNLOCK(lastRequestId_lock);
        _responseCode=HTTP_RESPONSE_CODE_OK;
        self.awaitingCompletion = NO;
        _responseHeaders = [[NSMutableDictionary alloc]init];

    }
    return self;
}

- (NSString *)name
{
    return [NSString stringWithFormat:@"HTTPRequest #%lu",(unsigned long)_requestId ];
}

- (NSString *)description2
{
    NSMutableString *desc;
    
    desc = [[NSMutableString alloc] initWithString:@"UMHTTPRequest dump starts\n"];
    [desc appendFormat:@"listening connection %p\n", _connection];
	[desc appendFormat:@"request method was <%@>\n", _method ? _method : @""];
	[desc appendFormat:@"protocol version was <%@>\n", _protocolVersion ? _protocolVersion : @""];
    [desc appendFormat:@"connection header had value <%@>\n", _connectionValue ? _connectionValue : @""];
	[desc appendFormat:@"path was <%@>\n", _path ? _path : @""];
	[desc appendFormat:@"url was <%@>\n",_url ? _url : @""];
    if (_requestHeaders)
    {
	    [desc appendFormat:@"request headers were %@\n", _requestHeaders];
    }
    if (_responseHeaders)
    {
	    [desc appendFormat:@"response headers were %@\n", _responseHeaders];
    }
    if (_requestCookies)
    {
	    [desc appendFormat:@"request cookies were %@\n", _requestCookies];
    }
    if (_responseCookies)
    {
	    [desc appendFormat:@"response cookies were %@\n", _responseCookies];
    }
	[desc appendFormat:@"request data was <%@>\n", _requestData ? _requestData : @""];
	[desc appendFormat:@"response data was <%@>\n", _responseData ? _responseData : @""];
    if (_params)
	    [desc appendFormat:@"params were %@\n", _params];
	[desc appendFormat:@"response code was %@\n", [self responseCodeAsString]];
    [desc appendFormat:@"authentication status was %@\n", [self authenticationStatusAsString]];
    [desc appendFormat:@"awaitingCompletion %@\n", (self.awaitingCompletion ? @"YES" : @"NO")];
    [desc appendFormat:@"sleeper %@\n", (_sleeper ? @"SET" : @"NULL")];    
    [desc appendString:@"UMHTTPRequest dump ends\n"];
    return desc;
}

- (void) setNotFound
{
    _responseCode = HTTP_RESPONSE_CODE_NOT_FOUND;
    NSString *text =
        @"<!DOCTYPE HTML PUBLIC \"-//IETF//DTD HTML 2.0//EN\">\r\n"
        @"<HTML><HEAD>\r\n"
        @"<TITLE>404 Page Not Foundd</TITLE>\r\n"
        @"</HEAD><BODY>\r\n"
    @"<H1>404 Page Not Found</H1>\r\n";
    [self setResponseHtmlString:text];
}

- (void) setRequireAuthentication
{
    _responseCode = HTTP_RESPONSE_CODE_UNAUTHORISED;
}

- (void) extractGetParams
{
    self.url = [[NSURL alloc]initWithString:_path];
    if(self.url==NULL)
    {
        NSLog(@"can not decode URL %@",_path);
    }
	[self extractParams:[_url query]];
}

- (void) extractPutParams
{
    self.url = [[NSURL alloc]initWithString:_path];
    if(self.url==NULL)
    {
        NSLog(@"can not decode URL %@",_path);
    }
	[self extractParams:[_url query]];
}

- (void) extractPostParams;
{
    self.url = [[NSURL alloc]initWithString:_path];
    if(self.url==NULL)
    {
        NSLog(@"can not decode URL %@",_path);
    }
    NSString *requestDataString = [[NSString alloc]initWithBytes:[_requestData bytes] length:[_requestData length] encoding:NSUTF8StringEncoding];
	[self extractParams:requestDataString];
}

- (NSMutableDictionary *)paramsMutableCopy
{
    return [[NSMutableDictionary alloc]initWithDictionary:_params];
}

- (void) extractParams:(NSString *)query
{
	NSMutableDictionary *d;
	NSArray		*items;
	NSString	*itemString;
	NSArray		*item;
	NSString	*tag;
	NSString	*value;

	_params = nil;
	if(query == nil)
    {
		return;
    }
	d = [[NSMutableDictionary alloc] initWithCapacity: 30];
	
	items = [query componentsSeparatedByString:@"&"];
	for (itemString in items)
	{
		item  = [itemString componentsSeparatedByString:@"="];
        if ([item count] == 2)
        {
		    tag = [item objectAtIndex:0];
		    value = [item objectAtIndex:1];
		    [d setObject:value forKey:tag];;
        }
	}
	_params = [[NSDictionary alloc] initWithDictionary:d];
}

- (void) setRequestHeader:(NSString *)name withValue:(NSString *)value
{
	if(_requestHeaders==nil)
    {
		_requestHeaders = [[NSMutableDictionary alloc]init];
    }
	[_requestHeaders setObject:value forKey:name];

    if([name isEqualToString:@"Authorization"])
    {
        if([value hasPrefix:@"Basic "])
        {
            NSString *auth = [value substringFromIndex:6];
            NSData *auth2 = [auth decodeBase64];
            NSString *user_and_pass = [[NSString alloc]initWithData:auth2 encoding:NSUTF8StringEncoding];
            NSArray *parts = [user_and_pass componentsSeparatedByString:@":"];
            if([parts count]==2)
            {
                _authUsername = parts[0];
                _authPassword = parts[1];
            }
        }
    }
    if([name isEqualToString:@"Cookie"])
    {
        value = [value stringByTrimmingCharactersInSet:[UMObject whitespaceAndNewlineCharacterSet]];
        
        NSArray *items = [value componentsSeparatedByString:@";"];
        for (NSString *itemString in items)
        {
            
            NSArray *item  = [itemString componentsSeparatedByString:@"="];
            if ([item count] == 2)
            {
                UMHTTPCookie *cookie = [[UMHTTPCookie alloc]init];
                cookie.name     = [[item objectAtIndex:0] stringByTrimmingCharactersInSet:[UMObject whitespaceAndNewlineCharacterSet]];
                cookie.value    = [[item objectAtIndex:1] stringByTrimmingCharactersInSet:[UMObject whitespaceAndNewlineCharacterSet]];
                [self setRequestCookie:cookie];
                
            }
        }
    }
}

- (void)setRequestCookie:(UMHTTPCookie *)cookie
{
	if(_requestCookies==nil)
    {
		_requestCookies = [[NSMutableDictionary alloc]init];
    }
	[_requestCookies setObject:cookie forKey:cookie.name];
}


- (void)setResponseCookie:(UMHTTPCookie *)cookie
{
	if(_responseCookies==nil)
    {
		_responseCookies = [[NSMutableDictionary alloc]init];
    }
	[_responseCookies setObject:cookie forKey:cookie.name];
}

- (void) setRequestHeadersFromArray:(NSMutableArray *)array
{
    long i, len;
    NSString *name;
    NSMutableString *value;
    
    len = [array count];
    if ([array count] > 0)
    {
        for (i = 0; i < len; i++)
        {
            [array getHeaderAtIndex:i withName:&name andValue:&value];
            if([name isEqualToString:@"Cookie"])
            {
                value = [[value stringByTrimmingCharactersInSet:[UMObject whitespaceAndNewlineCharacterSet]]mutableCopy];
                NSArray *items = [value componentsSeparatedByString:@";"];
                for (NSString *itemString in items)
                {
                    NSArray *item  = [itemString componentsSeparatedByString:@"="];
                    if ([item count] == 2)
                    {
                        UMHTTPCookie *cookie = [[UMHTTPCookie alloc]init];
                        cookie.name     = [[item objectAtIndex:0] stringByTrimmingCharactersInSet:[UMObject whitespaceAndNewlineCharacterSet]];
                        cookie.value    = [[item objectAtIndex:1] stringByTrimmingCharactersInSet:[UMObject whitespaceAndNewlineCharacterSet]];
                        [self setRequestCookie:cookie];

                    }
                }

            }
            id currentHeader = [_requestHeaders objectForKey:value];
            if(currentHeader == NULL)
            {
                NSMutableArray *currentArray = [[NSMutableArray alloc]init];
                [currentArray addObject:value];
                [_requestHeaders setObject:currentArray forKey:name];
            }
            else
            {
                NSMutableArray *currentArray = currentHeader;
                [currentArray addObject:value];
                [_requestHeaders setObject:currentArray forKey:name];
            }
        }
    }
}

- (void) removeRequestHeader:(NSString *)name
{
    [_requestHeaders removeObjectForKey:name];
}

- (void) setResponseHeader:(NSString *)name withValue:(NSString *)value
{
    if(value == NULL)
    {
        value = @"";
    }
	[_responseHeaders setObject:value forKey:name];
}


- (void)setResponseTypeText
{
    [self setResponseHeader:@"Content-Type" withValue:@"text/plain"];

}
- (void)setResponseTypeHtml
{
    [self setResponseHeader:@"Content-Type" withValue:@"text/html; charset=utf-8"];
}

- (void)setResponseTypeCss
{
    [self setResponseHeader:@"Content-Type" withValue:@"text/css"];
}

- (void)setResponseTypePng
{
    [self setResponseHeader:@"Content-Type" withValue:@"image/png"];
    
}

- (void)setResponseTypeJavascript
{
    [self setResponseHeader:@"Content-Type" withValue:@"text/javascript"];
}

- (void)setResponseTypeJpeg
{
    [self setResponseHeader:@"Content-Type" withValue:@"image/jpeg"];
}


- (void)setResponseTypeGif
{
    [self setResponseHeader:@"Content-Type" withValue:@"image/gif"];
    
}

- (void)setResponseTypeJson
{
    [self setResponseHeader:@"Content-Type" withValue:@"application/json"];
}

- (void)setResponseTypeBinary
{
    [self setResponseHeader:@"Content-Type" withValue:@"application/octet-stream"];
}


- (void)setCookie:(NSString *)cookieName withValue:(NSString *)value
{
    [self setCookie:cookieName withValue:value forPath:@"/"];
}



- (void)setCookie:(NSString *)cookieName withValue:(NSString *)value forPath:(NSString *)p
{
    UMHTTPCookie *cookie = [[UMHTTPCookie alloc]init];
    cookie.name = cookieName;
    cookie.value = value;
    cookie.path = p;
    [self setResponseCookie:cookie];
}

- (void)setCookie:(NSString *)cookieName withValue:(NSString *)value forPath:(NSString *)p expires:(NSDate *)expDate
{
    UMHTTPCookie *cookie = [[UMHTTPCookie alloc]init];
    cookie.name = cookieName;
    cookie.value = value;
    cookie.path = p;
    cookie.expiration = expDate;
    [self setResponseCookie:cookie];
}

- (UMHTTPCookie *)getCookie:(NSString *)name
{
    return [_requestCookies objectForKey:name];
}

- (NSString *)responseCodeAsString
{
    switch(_responseCode)
    {
        case HTTP_RESPONSE_CODE_CONTINUE:
            return @"Continue";
        case HTTP_RESPONSE_CODE_SWITCHING_PROTOCOLS:
            return @"Switching Protocols";
        case HTTP_RESPONSE_CODE_OK:
            return @"OK";
        case HTTP_RESPONSE_CODE_CREATED:
            return @"Created";
        case HTTP_RESPONSE_CODE_ACCEPTED:
            return @"Accepted";
        case HTTP_RESPONSE_CODE_NON_AUTHORITATIVE:
            return @"Non-Authoritative Information";
        case HTTP_RESPONSE_CODE_NO_CONTENT:
            return @"No Content";
        case HTTP_RESPONSE_CODE_RESET_CONTENT:
            return @"Reset Content";
        case HTTP_RESPONSE_CODE_PARTIAL_CONTENT:
            return @"Partial Content";
        case HTTP_RESPONSE_CODE_MULTIPLE_CHOICES:
            return @"Multiple Choices";
        case HTTP_RESPONSE_CODE_MOVED_PERMANENTLY:
            return @"Moved Permanently";
        case HTTP_RESPONSE_CODE_FOUND:
            return @"Found";
        case HTTP_RESPONSE_CODE_SEE_OTHER:
            return @"See Other";
        case HTTP_RESPONSE_CODE_NOT_MODIFIED:
            return @"Not Modified";
        case HTTP_RESPONSE_CODE_USE_PROXY:
            return @"Use Proxy";
        case HTTP_RESPONSE_CODE_UNUSED:
            return @"(Unused)";
        case HTTP_RESPONSE_CODE_TEMPORARY_REDIRECT:
            return @"Temporary Redirect";
        case HTTP_RESPONSE_CODE_BAD_REQUEST:
            return @"Bad Request";
        case HTTP_RESPONSE_CODE_UNAUTHORISED:
            return @"Unauthorised";
        case HTTP_RESPONSE_CODE_PAYMENT_REQUIRED:
            return @"Payment Required";
        case HTTP_RESPONSE_CODE_FORBIDDEN:
            return @"Forbidden";
        case HTTP_RESPONSE_CODE_NOT_FOUND:
            return @"Not Found";
        case HTTP_RESPONSE_CODE_METHOD_NOT_ALLOWED:
            return @"Method Not Allowed";
        case HTTP_RESPONSE_CODE_NOT_ACCEPTABLE:
            return @"Not Acceptable";
        case HTTP_RESPONSE_CODE_PROXY_AUTHENTICATION_REQUIRED:
            return @"Proxy Authentication Required";
        case HTTP_RESPONSE_CODE_REQUEST_TIMEOUT:
            return @"Request Timeout";
        case HTTP_RESPONSE_CODE_CONFLICT:
            return @"Conflict";
        case HTTP_RESPONSE_CODE_GONE:
            return @"Gone";
        case HTTP_RESPONSE_CODE_LENGTH_REQUIRED:
            return @"Length Required";
        case HTTP_RESPONSE_CODE_PRECONDITION_FAILED:
            return @"Precondition Failed";
        case HTTP_RESPONSE_CODE_REQUEST_ENTITY_TOO_LARGE:
            return @"Request Entity Too Large";
        case HTTP_RESPONSE_CODE_REQUEST_URI_TOO_LONG:
            return @"Request-URI Too Long";
        case HTTP_RESPONSE_CODE_UNSUPPORTED_MEDIA_TYPE:
            return @"Unsupported Media Type";
        case HTTP_RESPONSE_CODE_REQUESTED_RANGE_NOT_SATISFIABLE:
            return @"Requested Range Not Satisfiable";
        case HTTP_RESPONSE_CODE_EXPECTATION_FAILED:
            return @"Expectation Failed";
        case HTTP_RESPONSE_CODE_INTERNAL_SERVER_ERROR:
            return @"Internal Server Error";
        case HTTP_RESPONSE_CODE_NOT_IMPLEMENTED:
            return @"Not Implemented";
        case HTTP_RESPONSE_CODE_BAD_GATEWAY:
            return @"Bad Gateway";
        case HTTP_RESPONSE_CODE_SERVICE_UNAVAILABLE:
            return @"Service Unavailable";
        case HTTP_RESPONSE_CODE_GATEWAY_TIMEOUT:
            return @"Gateway Timeout";
        case HTTP_RESPONSE_CODE_HTTP_VERSION_NOT_SUPPORTED:
            return @"HTTP Version Not Supported";
        default:
            return @"Unknown";
    }
}

- (NSString *)authenticationStatusAsString
{
    switch(_authenticationStatus)
    {
        case UMHTTP_AUTHENTICATION_STATUS_UNTESTED:
            return @"untested";
        case UMHTTP_AUTHENTICATION_STATUS_FAILED:
            return @"failed";
        case UMHTTP_AUTHENTICATION_STATUS_PASSED:
            return @"passed";
        case UMHTTP_AUTHENTICATION_STATUS_NOT_REQUESTED:
            return @"not requested";
        default:
            return @"unknown";
    }
}

- (NSData *)extractResponse
{
    NSMutableData *d = [NSMutableData dataWithData:[self extractResponseHeader]];
    [d appendData:_responseData];
    return (NSData *)d;
}

- (NSData *)extractResponseHeader
{
    BOOL lengthSet = NO;
    NSString *eol = @"\r\n";
    
    NSMutableString *s = [NSMutableString stringWithFormat: @"%@ %03d %@%@",_protocolVersion,_responseCode,[self responseCodeAsString],eol];
    for(NSString *key in _responseHeaders)
    {
        NSObject *value = [_responseHeaders objectForKey:key];
        if([key isEqualToString:@"Content-Length"] && ![_method isEqualToString:@"HEAD"])
        {
            [s appendFormat:@"Content-Length: %lu%@",(unsigned long)[_responseData length],eol];
            lengthSet = YES;
        }
        else
        {
            if([value isKindOfClass:[NSString class]])
            {
                [s appendFormat:@"%@: %@%@",key,value,eol];
            }
            else if([value isKindOfClass:[NSArray class]])
            {
                NSArray *items = (NSArray *)value;
                for(NSString *item in items)
                {
                    [s appendFormat:@"%@: %@%@",key,item,eol];
                }
            }
        }
    }

    for(NSString *cookieKey in _responseCookies)
    {
        UMHTTPCookie *cookie = [_responseCookies objectForKey:cookieKey];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss Z"; //RFC2822-Format
        NSString *dateString = [dateFormatter stringFromDate:cookie.expiration];
        [s appendFormat:@"Set-Cookie: %@=%@; path=%@; expires=%@%@",cookie.name,cookie.value,cookie.path,dateString,eol];
    }

    if(lengthSet==NO && ![_method isEqualToString:@"HEAD"])
    {
        [s appendFormat:@"Content-Length: %lu%@",(unsigned long)[_responseData length],eol];
    }
    [s appendFormat:@"%@",eol];
    return [s dataUsingEncoding:NSUTF8StringEncoding];
}

- (void) setResponseHtmlString:(NSString *)content
{
    [self setContentType:@"text/html; charset=UTF-8"];
    _responseData = [content dataUsingEncoding:NSUTF8StringEncoding];
}

- (void) setResponsePlainText:(NSString *)content
{
    [self setResponseTypeText];
    _responseData = [content dataUsingEncoding:NSUTF8StringEncoding];
}

- (void) appendResponsePlainText:(NSString *)content
{
    [self setResponseTypeText];
    NSMutableData *mdata = [_responseData mutableCopy];
    [mdata appendData:[content dataUsingEncoding:NSUTF8StringEncoding]];
    _responseData=[mdata copy];
}

- (void) setResponseCssString:(NSString *)content
{ 
    [self setResponseTypeCss];
    _responseData=[content dataUsingEncoding:NSUTF8StringEncoding];
}


- (void) setResponseJsonString:(NSString *)content
{
    [self setResponseTypeJson];
    _responseData=[content dataUsingEncoding:NSUTF8StringEncoding];
}

- (void) setResponseJsonObject:(id)content
{
    [self setResponseTypeJson];
    UMJsonWriter *writer = [[UMJsonWriter alloc]init];
    writer.humanReadable = YES;
    NSString *string =  [writer stringWithObject:content];
    if((string.length == 0) && (writer.error.length > 0))
    {
        string = writer.error;
    }
    _responseData=[string dataUsingEncoding:NSUTF8StringEncoding];
}

- (void)setContentType:(NSString *)ct
{
    [self setResponseHeader: @"Content-Type" withValue: ct];
}


/* backwards compatibility */
- (void)setNotAuthorizedForRealm:(NSString *)realm
{
    [self setNotAuthorisedForRealm:realm];
}

- (void)setNotAuthorisedForRealm:(NSString *)realm
{
    _responseCode = HTTP_RESPONSE_CODE_UNAUTHORISED;
    [self setResponseHeader:@"WWW-Authenticate" withValue:[NSString stringWithFormat:@"Basic real=\"%@\"",realm]];
    NSString *text =
        @"<!DOCTYPE HTML PUBLIC \"-//IETF//DTD HTML 2.0//EN\">\r\n"
        @"<HTML><HEAD>\r\n"
        @"<TITLE>401 Authorization Required</TITLE>\r\n"
        @"</HEAD><BODY>\r\n"
        @"<H1>Authorization Required</H1>\r\n"
        @"This server could not verify that you\r\n"
        @"are authorised to access the document\r\n"
        @"requested.  Either you supplied the wrong\r\n"
        @"credentials (e.g., bad password), or your\r\n"
        @"browser doesn\'t understand how to supply\r\n";
    [self setResponseHtmlString:text];
}

- (void)makeAsync
{
    [self makeAsyncWithTimeout:DEFAULT_UMHTTP_SERVER_TIMEOUT];
}

- (void)makeAsyncWithTimeout:(NSTimeInterval)timeoutInSeconds
{
    self.awaitingCompletion = YES;
    self.completionTimeout = [NSDate dateWithTimeIntervalSinceNow:timeoutInSeconds];
    _pendingRequestLock = [[UMMutex alloc]initWithName:@"http-pending-request-lock"];
}

- (void)makeAsyncWithTimeout:(NSTimeInterval)timeoutInSeconds delegate:(id<UMHTTPRequest_TimeoutProtocol>)callback
{
    self.timeoutDelegate = callback;
    self.awaitingCompletion = YES;
    self.completionTimeout = [NSDate dateWithTimeIntervalSinceNow:timeoutInSeconds];
    _pendingRequestLock = [[UMMutex alloc]initWithName:@"http-pending-request-lock"];
}

- (void)resumePendingRequest
{
    UMMUTEX_LOCK(_pendingRequestLock);

    if(self.connection) /* we cant do the work twice */
    {
        self.awaitingCompletion = NO;
        [self finishRequest];
        self.connection = NULL;
    }
    UMMUTEX_UNLOCK(_pendingRequestLock);
}

- (void)sleepUntilCompleted
{
    self.awaitingCompletion  = YES;
    [_connection.server.pendingRequests addObject:self];
}

- (void)redirect:(NSString *)newPath
{
    [self setResponseHeader:@"Location" withValue:newPath];
    NSString *responseText = [NSString stringWithFormat:@"<h4>Redirecting to <a href=\"%@\">%@</a></h4>",newPath,newPath];
    _responseData = [responseText dataUsingEncoding:NSUTF8StringEncoding];
    _responseCode = HTTP_RESPONSE_CODE_TEMPORARY_REDIRECT;
}

- (void)finishRequest
{
#ifdef HTTP_DEBUG
    NSLog(@"[%@]: finishRequest called",self.name);
#endif

    [_connection.server.pendingRequests removeObject:self];
    NSString *serverName = _connection.server.serverName;

    [self setResponseHeader:@"Server" withValue:serverName];
    if(_connection.enableKeepalive)
    {
        [self setResponseHeader:@"Keep-Alive" withValue:@"timeout=4, max=100"];
        [self setResponseHeader:@"Connection" withValue:@"Keep-Alive"];
    }
    else
    {
        [self setResponseHeader:@"Connection" withValue:@"close"];
    }
    NSData *resp = [self extractResponse];
    [_connection.socket sendData:resp];
    _connection.currentRequest = NULL; /* our answer is complete */

    if(_connection.mustClose)
    {
#ifdef HTTP_DEBUG
        NSLog(@"[%@]: connection.mustClose is set. listener should now terminate",self.name);
#endif
        _connection = NULL; /* we give up ownership of the connection */
    }
    else
    {
#ifdef HTTP_DEBUG
        NSLog(@"[%@]: connection.mustClose is not set. requeuing read request",self.name);
#endif
        UMHTTPTask_ReadRequest *task = [[UMHTTPTask_ReadRequest alloc]initWithConnection:_connection];
        [_connection.server.taskQueue queueTask:task];
    }
}


- (void)setMimeTypeFromExtension:(NSString *)extension
{
    if([extension isEqualToStringCaseInsensitive:@"html"])
    {
        [self setResponseTypeHtml];
    }
    else if([extension isEqualToStringCaseInsensitive:@"txt"])
    {
        [self setResponseTypeText];
    }
    else if([extension isEqualToStringCaseInsensitive:@"png"])
    {
        [self setResponseTypePng];
    }
    else if([extension isEqualToStringCaseInsensitive:@"css"])
    {
        [self setResponseTypeCss];
    }
    else if([extension isEqualToStringCaseInsensitive:@"jpeg"])
    {
        [self setResponseTypeJpeg];
    }
    else if([extension isEqualToStringCaseInsensitive:@"gif"])
    {
        [self setResponseTypeGif];
    }
    else if([extension isEqualToStringCaseInsensitive:@"json"])
    {
        [self setResponseTypeJson];
    }
    else
    {
        [self setResponseTypeBinary];
    }
}

- (UMHTTPRequest *)copyWithZone:(NSZone *)zone
{
    UMHTTPRequest *r = [[UMHTTPRequest allocWithZone:zone]init];
    r.requestId = _requestId;
    r.completionTimeout = _completionTimeout;
    r.awaitingCompletion = _awaitingCompletion;
    r.connection = _connection;
    r.method = _method;
    r.protocolVersion = _protocolVersion;
    r.connectionValue = _connectionValue;
    r.path = _path;
    r.url = _url;
    r.requestHeaders = [_requestHeaders copy];
    r.responseHeaders = [_responseHeaders copy];
    r.requestData = _requestData;
    r.responseData = _responseData;
    r.params = _params;
    r.responseCode = _responseCode;
    r.authenticationStatus = _authenticationStatus;
    r.requestCookies = [_requestCookies copy];
    r.responseCookies = [_responseCookies copy];
    r.authUsername = _authUsername;
    r.authPassword = _authPassword;
    r.timeoutDelegate = _timeoutDelegate;
    r.mustClose = _mustClose;
    r.documentRoot = _documentRoot;
    r.isWebSocketRequest = _isWebSocketRequest;
    return r;
}
@end
