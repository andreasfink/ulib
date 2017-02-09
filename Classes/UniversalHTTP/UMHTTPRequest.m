//
//  UMHTTPRequest.m
//  UniversalHTTP
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMHTTPRequest.h"
#import "NSMutableArray+UMHTTP.h"
#import "NSMutableString+UMHTTP.h"
#import "NSString+UMHTTP.h"
#import "UMSleeper.h"
#import "UMHTTPCookie.h"
#import "UMJsonWriter.h"
@implementation UMHTTPRequest

@synthesize connection;
//@synthesize request;
//@synthesize response;
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
@synthesize awaitingCompletion;
@synthesize requestCookies;
@synthesize responseCookies;
@synthesize params;
@synthesize timeoutDelegate;
@synthesize authUsername;
@synthesize authPassword;
@synthesize completionTimeout;

- (id) init
{
    self = [super init];
    if(self)
	{
        responseCode=HTTP_RESPONSE_CODE_OK;
        awaitingCompletion = NO;
    }
    return self;
}

- (NSString *)description
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
    [desc appendFormat:@"awaitingCompletion %@\n", (awaitingCompletion ? @"YES" : @"NO")];
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
	[self extractParams:[url query]];
}

- (void) extractPutParams
{
    self.url = [[NSURL alloc]initWithString:path];
	[self extractParams:[url query]];
}

- (void) extractPostParams;
{
    self.url = [[NSURL alloc]initWithString:path];
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
        value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        NSArray *items = [value componentsSeparatedByString:@";"];
        for (NSString *itemString in items)
        {
            
            NSArray *item  = [itemString componentsSeparatedByString:@"="];
            if ([item count] == 2)
            {
                UMHTTPCookie *cookie = [[UMHTTPCookie alloc]init];
                cookie.name     = [[item objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                cookie.value    = [[item objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
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
                value = [[value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]mutableCopy];
                NSArray *items = [value componentsSeparatedByString:@";"];
                for (NSString *itemString in items)
                {
                    NSArray *item  = [itemString componentsSeparatedByString:@"="];
                    if ([item count] == 2)
                    {
                        UMHTTPCookie *cookie = [[UMHTTPCookie alloc]init];
                        cookie.name     = [[item objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        cookie.value    = [[item objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
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
	if(responseHeaders==nil)
    {
		responseHeaders = [[NSMutableDictionary alloc]init];
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

- (void) setResponseCssString:(NSString *)content
{ 
    [self setResponseTypeHtml];
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
    @synchronized (self)
    {
        awaitingCompletion = YES;
        self.completionTimeout = [NSDate dateWithTimeIntervalSinceNow:timeoutInSeconds];
    }
}

- (void)resumePendingRequest
{
    @synchronized (self)
    {
        awaitingCompletion = NO;
        [sleeper wakeUp];
    }
}


- (void)sleepUntilCompleted
{
    if(sleeper == NULL)
    {
        sleeper = [[UMSleeper alloc]initFromFile:__FILE__ line:__LINE__ function:__func__];
        [sleeper prepare];
    }

    BOOL a;
    @synchronized (self)
    {
        a = awaitingCompletion;
    }

    while(a==YES)
    {
        [sleeper sleep:100000LL]; /* sleep 100ms = 100'000µs or until being woken up */
        NSDate *d;
        @synchronized (self)
        {
            d =self.completionTimeout;
        }
        if([[NSDate date]compare:d] != NSOrderedAscending)
        {
            [timeoutDelegate httpRequestTimeout:self];
            @synchronized (self)
            {
                awaitingCompletion = NO;
            }
        }
        @synchronized (self)
        {
            a = awaitingCompletion;
        }
    }
    @synchronized (self)
    {
        awaitingCompletion = NO;
    }
    sleeper = NULL;
}

- (void)redirect:(NSString *)newPath
{
    [self setResponseHeader:@"Location" withValue:newPath];
    NSString *responseText = [NSString stringWithFormat:@"<h4>Redirecting to <a href=\"%@\">%@</a></h4>",newPath,newPath];
    self.responseData = [responseText dataUsingEncoding:NSUTF8StringEncoding];
    self.responseCode = HTTP_RESPONSE_CODE_TEMPORARY_REDIRECT;
}

@end
