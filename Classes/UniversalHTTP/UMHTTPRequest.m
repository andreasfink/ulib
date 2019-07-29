//
//  UMHTTPRequest.m
//  UniversalHTTP
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMHTTPRequest.h"
#import "UMHTTPConnection.h"
#import "UMHTTPServer.h"
#import "UMSocket.h"
#import "NSMutableArray+UMHTTP.h"
#import "NSMutableString+UMHTTP.h"
#import "NSString+UMHTTP.h"
#import "UMSleeper.h"
#import "UMHTTPCookie.h"
#import "UMJsonWriter.h"
#import "UMHTTPTask_ReadRequest.h"
#import "UMTaskQueue.h"
#import "UMSynchronizedArray.h"

@implementation UMHTTPRequest

@synthesize connection;
@synthesize method;
@synthesize protocolVersion;
@synthesize connectionValue;
@synthesize path;
@synthesize url;
@synthesize requestData;
@synthesize responseData;
@synthesize requestHeaders;
@synthesize responseHeaders;
@synthesize responseCode;
@synthesize authenticationStatus;
@synthesize requestCookies;
@synthesize responseCookies;
@synthesize params;
@synthesize timeoutDelegate;
@synthesize authUsername;
@synthesize authPassword;

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
        [lastRequestId_lock lock];
        _requestId = ++lastRequestId;
        _completionTimeout = [NSDate dateWithTimeIntervalSinceNow:120];
        [lastRequestId_lock unlock];
        responseCode=HTTP_RESPONSE_CODE_OK;
        self.awaitingCompletion = NO;
        responseHeaders = [[NSMutableDictionary alloc]init];

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
    [desc appendFormat:@"listening connection %p\n", connection];
	[desc appendFormat:@"request method was <%@>\n", method ? method : @""];
	[desc appendFormat:@"protocol version was <%@>\n", protocolVersion ? protocolVersion : @""];
    [desc appendFormat:@"connection header had value <%@>\n", connectionValue ? connectionValue : @""];
	[desc appendFormat:@"path was <%@>\n", path ? path : @""];
	[desc appendFormat:@"url was <%@>\n",url ? url : @""];
    if (requestHeaders)
    {
	    [desc appendFormat:@"request headers were %@\n", requestHeaders];
    }
    if (responseHeaders)
    {
	    [desc appendFormat:@"response headers were %@\n", responseHeaders];
    }
    if (requestCookies)
    {
	    [desc appendFormat:@"request cookies were %@\n", requestCookies];
    }
    if (responseCookies)
    {
	    [desc appendFormat:@"response cookies were %@\n", responseCookies];
    }
	[desc appendFormat:@"request data was <%@>\n", requestData ? requestData : @""];
	[desc appendFormat:@"response data was <%@>\n", responseData ? responseData : @""];
    if (params)
	    [desc appendFormat:@"params were %@\n", params];
	[desc appendFormat:@"response code was %@\n", [self responseCodeAsString]];
    [desc appendFormat:@"authentication status was %@\n", [self authenticationStatusAsString]];
    [desc appendFormat:@"awaitingCompletion %@\n", (self.awaitingCompletion ? @"YES" : @"NO")];
    [desc appendFormat:@"sleeper %@\n", (sleeper ? @"SET" : @"NULL")];    
    [desc appendString:@"UMHTTPRequest dump ends\n"];
    return desc;
}

- (void) setNotFound
{
    responseCode = HTTP_RESPONSE_CODE_NOT_FOUND;
}

- (void) setRequireAuthentication
{
    responseCode = HTTP_RESPONSE_CODE_UNAUTHORIZED;
}

- (void) extractGetParams
{
    self.url = [[NSURL alloc]initWithString:path];
    if(self.url==NULL)
    {
        NSLog(@"can not decode URL %@",path);
    }
	[self extractParams:[url query]];
}

- (void) extractPutParams
{
    self.url = [[NSURL alloc]initWithString:path];
    if(self.url==NULL)
    {
        NSLog(@"can not decode URL %@",path);
    }
	[self extractParams:[url query]];
}

- (void) extractPostParams;
{
    self.url = [[NSURL alloc]initWithString:path];
    if(self.url==NULL)
    {
        NSLog(@"can not decode URL %@",path);
    }
    NSString *requestDataString = [[NSString alloc]initWithBytes:[requestData bytes] length:[requestData length] encoding:NSUTF8StringEncoding];
	[self extractParams:requestDataString];
}

- (NSMutableDictionary *)paramsMutableCopy
{
    return [[NSMutableDictionary alloc]initWithDictionary:params];
}

- (void) extractParams:(NSString *)query
{
	NSMutableDictionary *d;
	NSArray		*items;
	NSString	*itemString;
	NSArray		*item;
	NSString	*tag;
	NSString	*value;

	params = nil;
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
	params = [[NSDictionary alloc] initWithDictionary:d];
}

- (void) setRequestHeader:(NSString *)name withValue:(NSString *)value
{
	if(requestHeaders==nil)
    {
		requestHeaders = [[NSMutableDictionary alloc]init];
    }
	[requestHeaders setObject:value forKey:name];

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
                self.authUsername = parts[0];
                self.authPassword = parts[1];
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
	if(requestCookies==nil)
    {
		requestCookies = [[NSMutableDictionary alloc]init];
    }
	[requestCookies setObject:cookie forKey:cookie.name];
}


- (void)setResponseCookie:(UMHTTPCookie *)cookie
{
	if(responseCookies==nil)
    {
		responseCookies = [[NSMutableDictionary alloc]init];
    }
	[responseCookies setObject:cookie forKey:cookie.name];
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
            id currentHeader = [requestHeaders objectForKey:value];
            if(currentHeader == NULL)
            {
                NSMutableArray *currentArray = [[NSMutableArray alloc]init];
                [currentArray addObject:value];
                [requestHeaders setObject:currentArray forKey:name];
            }
            else
            {
                NSMutableArray *currentArray = currentHeader;
                [currentArray addObject:value];
                [requestHeaders setObject:currentArray forKey:name];
            }
        }
    }
}

- (void) removeRequestHeader:(NSString *)name
{
    [requestHeaders removeObjectForKey:name];
}

- (void) setResponseHeader:(NSString *)name withValue:(NSString *)value
{
    if(value == NULL)
    {
        value = @"";
    }
	[responseHeaders setObject:value forKey:name];
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
    return [requestCookies objectForKey:name];
}

- (NSString *)responseCodeAsString
{
    switch(responseCode)
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
        case HTTP_RESPONSE_CODE_UNAUTHORIZED:
            return @"Unauthorized";
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
    switch(authenticationStatus)
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
    [d appendData:responseData];
    return (NSData *)d;
}

- (NSData *)extractResponseHeader
{
    BOOL lengthSet = NO;
    NSString *eol = @"\r\n";
    
    NSMutableString *s = [NSMutableString stringWithFormat: @"%@ %03d %@%@",protocolVersion,responseCode,[self responseCodeAsString],eol];
    for(NSString *key in responseHeaders)
    {
        NSObject *value = [responseHeaders objectForKey:key];
        if([key isEqualToString:@"Content-Length"] && ![method isEqualToString:@"HEAD"])
        {
            [s appendFormat:@"Content-Length: %lu%@",(unsigned long)[responseData length],eol];
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

    for(NSString *cookieKey in responseCookies)
    {
        UMHTTPCookie *cookie = [responseCookies objectForKey:cookieKey];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss Z"; //RFC2822-Format
        NSString *dateString = [dateFormatter stringFromDate:cookie.expiration];
        [s appendFormat:@"Set-Cookie: %@=%@; path=%@; expires=%@%@",cookie.name,cookie.value,cookie.path,dateString,eol];
    }

    if(lengthSet==NO && ![method isEqualToString:@"HEAD"])
    {
        [s appendFormat:@"Content-Length: %lu%@",(unsigned long)[responseData length],eol];
    }
    [s appendFormat:@"%@",eol];
    return [s dataUsingEncoding:NSUTF8StringEncoding];
}

- (void) setResponseHtmlString:(NSString *)content
{
    [self setContentType:@"text/html; charset=UTF-8"];
    [self setResponseData:[content dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void) setResponsePlainText:(NSString *)content
{
    [self setResponseTypeText];
    [self setResponseData:[content dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void) appendResponsePlainText:(NSString *)content
{
    [self setResponseTypeText];
    NSMutableData *mdata = [responseData mutableCopy];
    [mdata appendData:[content dataUsingEncoding:NSUTF8StringEncoding]];
    [self setResponseData:[mdata copy]];
}

- (void) setResponseCssString:(NSString *)content
{ 
    [self setResponseTypeCss];
    [self setResponseData:[content dataUsingEncoding:NSUTF8StringEncoding]];
}


- (void) setResponseJsonString:(NSString *)content
{
    [self setResponseTypeJson];
    [self setResponseData:[content dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void) setResponseJsonObject:(id)content
{
    [self setResponseTypeJson];
    UMJsonWriter *writer = [[UMJsonWriter alloc]init];
    writer.humanReadable = YES;
    NSString *string =  [writer stringWithObject:content];
    [self setResponseData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)setContentType:(NSString *)ct
{
    [self setResponseHeader: @"Content-Type" withValue: ct];
}

- (void)setNotAuthorizedForRealm:(NSString *)realm
{
    [self setResponseCode:HTTP_RESPONSE_CODE_UNAUTHORIZED];
    [self setResponseHeader:@"WWW-Authenticate" withValue:[NSString stringWithFormat:@"Basic real=\"%@\"",realm]];
    NSString *text =
        @"<!DOCTYPE HTML PUBLIC \"-//IETF//DTD HTML 2.0//EN\">\r\n"
        @"<HTML><HEAD>\r\n"
        @"<TITLE>401 Authorization Required</TITLE>\r\n"
        @"</HEAD><BODY>\r\n"
        @"<H1>Authorization Required</H1>\r\n"
        @"This server could not verify that you\r\n"
        @"are authorized to access the document\r\n"
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
    [_pendingRequestLock lock];
    if(self.connection) /* we cant do the work twice */
    {
        self.awaitingCompletion = NO;
        [self finishRequest];
        self.connection = NULL;
    }
    [_pendingRequestLock unlock];
}

- (void)sleepUntilCompleted
{
    self.awaitingCompletion  = YES;
    [connection.server.pendingRequests addObject:self];
}

- (void)redirect:(NSString *)newPath
{
    [self setResponseHeader:@"Location" withValue:newPath];
    NSString *responseText = [NSString stringWithFormat:@"<h4>Redirecting to <a href=\"%@\">%@</a></h4>",newPath,newPath];
    self.responseData = [responseText dataUsingEncoding:NSUTF8StringEncoding];
    self.responseCode = HTTP_RESPONSE_CODE_TEMPORARY_REDIRECT;
}

- (void)finishRequest
{
#ifdef HTTP_DEBUG
    NSLog(@"[%@]: finishRequest called",self.name);
#endif

    [connection.server.pendingRequests removeObject:self];
    NSString *serverName = connection.server.serverName;

    [self setResponseHeader:@"Server" withValue:serverName];
    if(connection.enableKeepalive)
    {
        [self setResponseHeader:@"Keep-Alive" withValue:@"timeout=4, max=100"];
        [self setResponseHeader:@"Connection" withValue:@"Keep-Alive"];
    }
    else
    {
        [self setResponseHeader:@"Connection" withValue:@"close"];
    }
    NSData *resp = [self extractResponse];
    [connection.socket sendData:resp];
    if(connection.mustClose)
    {
#ifdef HTTP_DEBUG
        NSLog(@"[%@]: connection.mustClose is set. listener should now terminate",self.name);
#endif
        connection = NULL; /* we give up ownership of the connection */
    }
    else
    {
#ifdef HTTP_DEBUG
        NSLog(@"[%@]: connection.mustClose is not set. requeuing read request",self.name);
#endif
        UMHTTPTask_ReadRequest *task = [[UMHTTPTask_ReadRequest alloc]initWithConnection:connection];
        [connection.server.taskQueue queueTask:task];
    }
}



@end
