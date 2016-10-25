//
//  UMTestDelegate.m
//  ulib
//
//  Created by Aarno Syvänen on 08.05.12.
//  Copyright (c) Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved
//

#import "UMTestDelegate.h"
#import "UMConfig.h"
#import "UMLogFeed.h"
#import "UMSocket.h"
#import "UMTestHTTP.h"
#import "NSMutableString+UMHTTP.h"

@interface UMAuthorizeConnectionDelegate (PRIVATE)

- (BOOL)patternList:(NSString *)l matchesIP:(NSString *)ip;
- (BOOL)pattern:(NSString *)p matchesIP:(NSString *)ip;

@end

@implementation UMAuthorizeConnectionDelegate (PRIVATE)

- (BOOL)pattern:(NSString *)p matchesIP:(NSString *)ip
{
    long i, j;
    long patLen, ipLen;
    int patC, ipC;
    
    patLen = [p length];
    ipLen = [ip length];
    
    i = 0;
    j = 0;
    while (i < patLen && j < ipLen) 
    {
	    patC = [p characterAtIndex:i];
	    ipC = [ip characterAtIndex:j];
	    if (patC == ipC)
        {
            /* The characters match, go to the next ones. */
	        ++i;
	        ++j;
	    } 
        else if (patC != '*') 
        {
            /* They differ, and the pattern isn't a wildcard one. */
	        return FALSE;
	    } 
        else 
        {
            /* We found a wildcard in the pattern. Skip in ip. */
	        ++i;
	        while (j < ipLen && ipC != '.') 
            {
		        ++j;
		        ipC = [ip characterAtIndex:j];
	        }
	    }
    }
    
    if (i >= patLen && j >= ipLen)
    	return TRUE;
    
    return FALSE;
}


- (BOOL)patternList:(NSString *)l matchesIP:(NSString *)ip
{
    NSArray *patterns;
    NSString *pattern;
    BOOL matches;
    
    patterns = [l componentsSeparatedByString:@";"];
    matches = 0;
    
    while (!matches && (pattern = patterns[0])) 
	    matches = [self pattern:pattern matchesIP:ip];
    
    return matches;
}

@end

@implementation UMAuthorizeConnectionDelegate

@synthesize serverAllowIP;
@synthesize serverDenyIP;
@synthesize subsection;

- (UMAuthorizeConnectionDelegate *)initWithConfigFile:(NSString *)file
{
    self = [super init];
    if(self)
    {
        UMConfig *cfg = [[UMConfig alloc] initWithFileName:file];
        
        [cfg allowSingleGroup:@"core"];
        [cfg allowSingleGroup:@"auth"];
        [cfg read]; 
        
        NSDictionary *grp = [cfg getSingleGroup:@"core"];
        if (!grp)
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"UMAuthorizeConne ctionDelegate. init: configuration file must have group core" userInfo:nil];
        
        self.serverAllowIP = grp[@"server-allow-ip"];
        if (!serverAllowIP)
            self.serverAllowIP = @"";
        self.serverDenyIP = grp[@"server-deny-ip"];
        if (!serverDenyIP)
            self.serverDenyIP = @"";
        if (serverAllowIP && !serverDenyIP)
            [logFeed info:0 inSubsection:subsection withText:@"Box connection allowed IPs defined without any denied...\r"];
    }
    return self;
}


- (UMHTTPServerAuthorizeResult) httpAuthorizeConnection:(UMSocket *)us
{
    NSString *ip;
    int type;
    
    ip = [us getRemoteAddress];
    ip = [UMSocket deunifyIp:ip type:&type];
    if (!ip)
        return UMHTTPServerAuthorize_blacklisted;
    
    if ([serverDenyIP length] == 0)
        return UMHTTPServerAuthorize_successful;
    
    if (serverAllowIP && [self patternList:serverAllowIP matchesIP:ip])
        return UMHTTPServerAuthorize_successful;
    
    if ([self patternList:serverDenyIP matchesIP:ip])
        return UMHTTPServerAuthorize_blacklisted;
    
    return UMHTTPServerAuthorize_blacklisted;
}

- (void) httpAuthorizeUrl:(UMHTTPRequest *)req
{

}

@end

@implementation UMDelegate

@synthesize content;
@synthesize subsection;

- (UMDelegate *)initWithConfigFile:(NSString *)file
{
    NSString *contentFile;
    NSString *contentString;
    NSError *error;
    NSString *oldPath;
    UMLogHandler *delegateLogHandler;
    
    if((self = [super init]))
    {
        UMConfig *cfg = [[UMConfig alloc] initWithFileName:file];
        
        [cfg allowSingleGroup:@"core"];
        [cfg allowSingleGroup:@"auth"];
        [cfg read]; 
        
        NSDictionary *grp = [cfg getSingleGroup:@"core"];
        if (!grp)
        {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"UMHTTPDelegate. init: configuration file must have group core" userInfo:nil];
        }
        contentFile = grp[@"content-file"];
        if (contentFile)
        {
            oldPath   = [[NSFileManager defaultManager] currentDirectoryPath];
            contentString = [NSString stringWithContentsOfFile:contentFile encoding:NSUTF8StringEncoding error:&error];
            if (contentString)
            {
                self.content = [contentString dataUsingEncoding:NSUTF8StringEncoding];
            }
        }
        
        delegateLogHandler = [[UMLogHandler alloc] initWithConsole];
        [self addLogFromConfigGroup:grp toHandler:delegateLogHandler sectionName:@"ulib tests" subSectionName:@"Universal HTTP tests"];
    }
    return self;
    
error:
    ;
    return nil;
}


@end


@implementation UMHTTPPostDelegate

- (UMHTTPPostDelegate *)init
{
    self=[super init];
    return self;
}



- (void) httpPost:(UMHTTPRequest *)req
{
    NSString *length;
    NSString *msg, *msg2;
    NSString *contentString; /* we are sending test content; certainly character data.*/
    NSMutableString *hdrs;
    NSDictionary *headers;
    NSData *data;
    NSArray *keys;
    NSArray *values;
    NSMutableString *body;
    long i, len;
    NSString *key;
    NSString *value;
    
    headers = [req requestHeaders];
    keys = [headers allKeys];
    values = [headers allValues];
    data = [req requestData];
    i = 0;
    len = [keys count];
    
    if (headers)
    {
        hdrs = [NSMutableString string];
        
        while (i < len)
        {
            key = keys[i];
            value = values[i];
            [hdrs appendFormat:@"%@: %@", key, value];
            [hdrs appendString: @" hend "];
            ++i;
        }
        
        [hdrs appendString: @" tend "];
        NSString *msg3 = [NSString stringWithFormat:@"Test HTTP: received post request headers %@ \r\n", hdrs];
        [logFeed info:0 inSubsection:subsection withText:msg3];
    }
    else
        [logFeed info:0 inSubsection:subsection withText:@"received post request with no headers"];
    
    if (data)
    {
        body = [[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [body replaceOccurrencesOfString:@"\r\n" withString:@"\n" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [body length])];
        [body replaceOccurrencesOfString:@"\n" withString:@" bend " options:NSCaseInsensitiveSearch range:NSMakeRange(0, [body length])];
        [body appendString:@" trend "];
        NSString *msg3 = [NSString stringWithFormat:@"Test HTTP: received post request body %@ \r\n", body];
        [logFeed info:0 inSubsection:subsection withText:msg3];
    }
    else
        [logFeed info:0 inSubsection:subsection withText:@"received post request with no body \r\n"];
    
    [req setResponseCode:HTTP_RESPONSE_CODE_OK];
    [req setResponseHeader:@"Connection" withValue:@"keep-alive"];
    if (content)
    {
        [req setResponseHeader:@"Content-Type" withValue:@"text/plain; charset=\"UTF-8\""];
        length = [NSString stringWithFormat:@"%lu", (unsigned long)[content length]];
        [req setResponseHeader:@"Content-Length" withValue:length];
        [req setResponseData:content];
    
        contentString = [[NSString alloc] initWithData:content encoding:NSUTF8StringEncoding];
        msg = [NSString stringWithFormat:@"Test HTTP: sent content %@ via post\r\n", contentString];
        [logFeed debug:0 inSubsection:subsection withText:msg];
        msg2 = [NSString stringWithFormat:@"Test HTTP: sent post reply headers with content type text/plain charset UTF-8 and content length %lu \r\n", (unsigned long)[content length]];
        [logFeed debug:0 inSubsection:subsection withText:msg2];
    }
    else
    {
        msg2 = [NSString stringWithFormat:@"Test HTTP: sent post reply headers %@", headers];
        [logFeed debug:0 inSubsection:subsection withText:msg2];
    }
}

@end

@implementation UMHTTPHeadDelegate

- (UMHTTPHeadDelegate *)init
{
    self=[super init];
    return self;
}


/* HTTP HEAD would return all headers, including Content-Length*/
- (void) httpHead:(UMHTTPRequest *)req
{
    NSString *length;
    NSString *msg2;
    NSDictionary *headers = headers;
    NSArray *keys;
    NSArray *values;
    NSData *data;
    long i,len;
    NSMutableString *hdrs;
    NSString *key, *value;
    NSMutableString *body;
    
    headers = [req requestHeaders];
    keys = [headers allKeys];
    values = [headers allValues];
    data = [req requestData];
    i = 0;
    len = [keys count];
    
    if (headers)
    {
        hdrs = [NSMutableString string];
        
        while (i < len)
        {
            key = keys[i];
            value = values[i];
            [hdrs appendFormat:@"%@: %@", key, value];
            [hdrs appendString: @" hend "];
            ++i;
        }
        
        [hdrs appendString: @" tend "];
        NSString *msg3 = [NSString stringWithFormat:@"Test HTTP: received head request headers %@ \r\n", hdrs];
        [logFeed info:0 inSubsection:subsection withText:msg3];
    }
    else
        [logFeed info:0 inSubsection:subsection withText:@"received head request with no headers"];
    
    if (data)
    {
        body = [[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [body replaceOccurrencesOfString:@"\r\n" withString:@"\n" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [body length])];
        [body replaceOccurrencesOfString:@"\n" withString:@" bend " options:NSCaseInsensitiveSearch range:NSMakeRange(0, [body length])];
        [body appendString:@" trend "];
        NSString *msg3 = [NSString stringWithFormat:@"Test HTTP: received head request body %@ \r\n", body];
        [logFeed info:0 inSubsection:subsection withText:msg3];
    }
    else
        [logFeed info:0 inSubsection:subsection withText:@"received head request with no body \r\n"];
    
    [req setResponseCode:HTTP_RESPONSE_CODE_OK];
    [req setResponseHeader:@"Content-Type" withValue:@"text/plain; charset=\"UTF-8\""];
    length = [NSString stringWithFormat:@"%lu", (unsigned long)[content length]];
    [req setResponseHeader:@"Content-Length" withValue:length];
    [req setResponseHeader:@"Connection" withValue:@"keep-alive"];
    
    msg2 = [NSString stringWithFormat:@"Test HTTP: sent head reply headers with content type text/plain charset UTF-8 and content length %lu \r\n", (unsigned long)[content length]];
    [logFeed debug:0 inSubsection:subsection withText:msg2];
}

@end

@implementation UMHTTPOptionsDelegate

- (UMHTTPOptionsDelegate *)init
{
    self=[super init];
    return self;
}


/* HTTP OPTIONS will return supported emthods*/
- (void) httpOptions:(UMHTTPRequest *)req
{
    NSString *msg2;
    NSDictionary *headers;
    NSArray *keys;
    NSArray *values;
    NSData *data;
    long i, len;
    NSMutableString *hdrs;
    NSString *key, *value;
    
    headers = [req requestHeaders];
    keys = [headers allKeys];
    values = [headers allValues];
    data = [req requestData];
    i = 0;
    len = [keys count];
    
    if (headers)
    {
        hdrs = [NSMutableString string];
        
        while (i < len)
        {
            key = keys[i];
            value = values[i];
            [hdrs appendFormat:@"%@: %@", key, value];
            [hdrs appendString: @" hend "];
            ++i;
        }
        
        [hdrs appendString: @" tend "];
        NSString *msg3 = [NSString stringWithFormat:@"Test HTTP: received options request headers %@ \r\n", hdrs];
        [logFeed info:0 inSubsection:subsection withText:msg3];
    }
    else
        [logFeed info:0 inSubsection:subsection withText:@"received head request with no headers"];
    
    [req setResponseCode:HTTP_RESPONSE_CODE_OK];
    [req setResponseHeader:@"Allow" withValue:@"GET, POST, HEAD, OPTIONS, TRACE, PUT"];
    [req setResponseHeader:@"Content-Length" withValue:@"0"];
    [req setResponseHeader:@"Connection" withValue:@"keep-alive"]; 
    
    msg2 = [NSString stringWithFormat:@"Test HTTP: sent options reply headers with allow GET, POST, HEAD, OPTIONS, TRACE, PUT and with content length 0 \r\n"];
    [logFeed debug:0 inSubsection:subsection withText:msg2];
}

@end

@implementation UMHTTPTraceDelegate

enum {
    HTTP_PORT = 80,
    HTTPS_PORT = 443
};

- (NSString *)rebuildRequestWithMethod:(NSString *)m withURL:(NSString *)u withHeaders:(NSMutableArray *)headers withBody:(NSString *)body
{
    /* XXX headers missing */
    NSMutableString *request;
    int i;
    
    request = [NSMutableString stringWithFormat:@"%@ %@ HTTP/1.1\r\n", m, u];
    
    for (i = 0; headers != NULL && i < [headers count]; ++i) {
        [request appendString:headers[i]];
        [request appendString:@"\r\n"];
    }
    [request appendString:@"\r\n"];
    
    if (body)
        [request appendString:body];
    
    return request;
}

- (UMHTTPTraceDelegate *)init
{
    self=[super init];
    return self;
}


/* HTTP TRACE will return request as content*/
- (void) httpTrace:(UMHTTPRequest *)req
{
    NSString *length;
    NSMutableData *request;
    NSString *requestString;
    NSMutableString *contentString;
    NSString *msg, *msg2;
    NSMutableString *dataString, *logString;
    NSMutableArray *headers;
    NSMutableString *hdrs;
    long i, len;
    
    dataString = [[NSMutableString alloc] initWithData:[req requestData] encoding:NSASCIIStringEncoding];
    if (dataString)
    {
        logString = [dataString mutableCopy];
        [logString replaceOccurrencesOfString:@"\r\n" withString:@"\n" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [logString length])];
        [logString replaceOccurrencesOfString:@"\n" withString:@" bend " options:NSCaseInsensitiveSearch range:NSMakeRange(0, [dataString length])];
        [logString appendString:@" trend "];
        NSString *msg3 = [NSString stringWithFormat:@"Test HTTP: received trace request body %@ \r\n", logString];
        [logFeed info:0 inSubsection:subsection withText:msg3];
    }
    else
        [logFeed info:0 inSubsection:subsection withText:@"received trace request with no body \r\n"];

    headers = [[req requestHeaders] toArray];
    if (headers)
    {
        hdrs = [NSMutableString string];
        i = 0;
        len = [headers count];
        while (i < len)
        {
            [hdrs appendFormat:@"%@", headers[i]];
            [hdrs appendString: @" hend "];
            ++i;
        }
        
        [hdrs appendString: @" tend "];
        NSString *msg3 = [NSString stringWithFormat:@"Test HTTP: received trace request headers %@ \r\n", hdrs];
        [logFeed info:0 inSubsection:subsection withText:msg3];
    }
    else
        [logFeed info:0 inSubsection:subsection withText:@"received trace request with no headers"];
    
    requestString = [self rebuildRequestWithMethod:[req method] withURL:[req path] withHeaders:headers withBody:dataString];
    request = [[requestString dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
    
    [req setResponseCode:HTTP_RESPONSE_CODE_OK];
    [req setResponseData:request];
    [req setResponseHeader:@"Content-Type" withValue:@"message/http"];
    length = [NSString stringWithFormat:@"%lu", (unsigned long)[request length]];
    [req setResponseHeader:@"Content-Length" withValue:length];
    [req setResponseHeader:@"Connection" withValue:@"keep-alive"];
    
    contentString = [[NSMutableString alloc] initWithData:request encoding:NSUTF8StringEncoding];
    [contentString replaceOccurrencesOfString:@"\r\n" withString:@"\n" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [contentString length])];
    [contentString replaceOccurrencesOfString:@"\n" withString:@" bend " options:NSCaseInsensitiveSearch range:NSMakeRange(0, [contentString length])];
    [contentString appendString:@" trend "];
    
    msg = [NSString stringWithFormat:@"Test HTTP: sent content %@ via trace\r\n", contentString];
    [logFeed debug:0 inSubsection:subsection withText:msg];
    
    msg2 = [NSString stringWithFormat:@"Test HTTP: sent trace reply headers with content type message/http and content length %lu \r\n", (unsigned long)[request length]];
    [logFeed debug:0 inSubsection:subsection withText:msg2];
}

@end


@implementation UMHTTPDelegate

- (UMHTTPDelegate *)init
{
    self=[super init];
    return self;
}


- (void) httpGet:(UMHTTPRequest *)req
{
    NSString *length;
    NSString *msg2, *msg;
    NSMutableString *contentString;
    NSDictionary *headers;
    NSArray *keys;
    NSArray *values;
    long i, len;
    NSMutableString *hdrs;
    NSString *key, *value;
    NSURL *url;
    NSString *urlString;
    NSString *protocolVersion;
    NSString *contentType;
    NSString *contentLength;
    
    protocolVersion = [req protocolVersion];
    url = [req url];
    urlString = [url absoluteString];
    headers = [req requestHeaders];
    keys = [headers allKeys];
    values = [headers allValues];
    
    if (headers)
    {
        hdrs = [NSMutableString string];
        i = 0;
        len = [keys count];
        while (i < len)
        {
            key = keys[i];
            value = values[i];
            [hdrs appendFormat:@"%@: %@", key, value];
            [hdrs appendString: @" hend "];
            if ([key isEqualToString:@"Content-Type"])
                contentType = value;
            if ([key isEqualToString:@"Content-Length"])
                contentLength = value;
            ++i;
        }
        
        [hdrs appendString: @" tend "];
        
        NSString *h = [headers[@"Content-Type"] mutableCopy];
        if (h)
        {
            NSString *msg3 = [NSString stringWithFormat:@"Test HTTP: received get request headers %@ with url %@ and version %@ and content type %@ and content length %@ fend \r\n\r\n", hdrs, urlString, protocolVersion ? protocolVersion : @"HTTP/1.1", contentType ? contentType : @"text/plain;charset=UTF-8", contentLength ? contentLength : @"0"];
            [logFeed info:0 inSubsection:subsection withText:msg3];
        }
        else
        {
            NSString *msg4 = [NSString stringWithFormat:@"Test HTTP: received get request headers %@ with url %@ and version %@ fend \r\n\r\n", hdrs, urlString, protocolVersion ? protocolVersion : @"HTTP/1.1"];
            [logFeed info:0 inSubsection:subsection withText:msg4];
        }
    }
    else
        [logFeed info:0 inSubsection:subsection withText:@"received get request with no headers"];
    
    [req setResponseCode:HTTP_RESPONSE_CODE_OK];
    [req setResponseHeader:@"Connection" withValue:@"keep-alive"];
    
    if (content)
    {
        [req setResponseHeader:@"Content-Type" withValue:@"text/plain; charset=\"UTF-8\""];
        length = [NSString stringWithFormat:@"%lu", (unsigned long)[content length]];
        [req setResponseHeader:@"Content-Length" withValue:length];
        [req setResponseData:content];
        contentString = [[NSMutableString alloc] initWithData:content encoding:NSUTF8StringEncoding];
        msg = [NSString stringWithFormat:@"Test HTTP: sent content %@ via get\r\n", contentString];
        [logFeed debug:0 inSubsection:subsection withText:msg];
        msg2 = [NSString stringWithFormat:@"Test HTTP: sent get reply headers with content type text/plain charset UTF-8 and content length %lu \r\n", (unsigned long)[content length]];
        [logFeed debug:0 inSubsection:subsection withText:msg2];
    }
}

@end

@implementation UMHTTPPutDelegate

- (UMHTTPPutDelegate *)init
{
    self=[super init];
    return self;
}


- (void) httpPut:(UMHTTPRequest *)req
{
    NSString *msg2;
    NSData *data;
    NSMutableString *body;
    NSMutableString *hdrs;
    NSDictionary *headers;
    NSArray *keys;
    NSArray *values;
    long i, len;
    NSString *key;
    NSString *value;
    
    headers = [req requestHeaders];
    keys = [headers allKeys];
    values = [headers allValues];
    
    if (headers)
    {
        hdrs = [NSMutableString string];
        i = 0;
        len = [keys count];
        while (i < len)
        {
            key = keys[i];
            value = values[i];
            [hdrs appendFormat:@"%@: %@", key, value];
            [hdrs appendString: @" hend "];
            ++i;
        }
        
        [hdrs appendString: @" tend "];
        NSString *msg3 = [NSString stringWithFormat:@"Test HTTP: received put request headers %@ \r\n", hdrs];
        [logFeed info:0 inSubsection:subsection withText:msg3];
    }
    else
        [logFeed info:0 inSubsection:subsection withText:@"received put request with no headers"];
    
    data = [req requestData];
    
    if (data)
    {
        body = [[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [body replaceOccurrencesOfString:@"\r\n" withString:@"\n" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [body length])];
        [body replaceOccurrencesOfString:@"\n" withString:@" bend " options:NSCaseInsensitiveSearch range:NSMakeRange(0, [body length])];
        [body appendString:@" trend "];
        NSString *msg3 = [NSString stringWithFormat:@"Test HTTP: received put request body %@ \r\n", body];
        [logFeed info:0 inSubsection:subsection withText:msg3];
    }
    else
        [logFeed info:0 inSubsection:subsection withText:@"received put request with no body \r\n"];
    
    [req setResponseCode:HTTP_RESPONSE_CODE_OK];
    [req setResponseHeader:@"Connection" withValue:@"keep-alive"];
    
    msg2 = [NSString stringWithFormat:@"Test HTTP: sent put reply headers with content length 0 \r\n"];
    [logFeed debug:0 inSubsection:subsection withText:msg2];
}

@end

@implementation UMHTTPDeleteDelegate

- (UMHTTPDeleteDelegate *)init
{
    self=[super init];
    return self;
}


- (void) httpDelete:(UMHTTPRequest *)req
{
    NSString *msg2;
    NSMutableString *hdrs;
    NSDictionary *headers;
    NSArray *keys;
    NSArray *values;
    long i, len;
    NSString *key;
    NSString *value;
    
    headers = [req requestHeaders];
    keys = [headers allKeys];
    values = [headers allValues];
    
    if (headers)
    {
        hdrs = [NSMutableString string];
        i = 0;
        len = [keys count];
        while (i < len)
        {
            key = keys[i];
            value = values[i];
            [hdrs appendFormat:@"%@: %@", key, value];
            [hdrs appendString: @" hend "];
            ++i;
        }
        
        [hdrs appendString: @" tend "];
        NSString *msg3 = [NSString stringWithFormat:@"Test HTTP: received delete request headers %@ \r\n", hdrs];
        [logFeed info:0 inSubsection:subsection withText:msg3];
    }
    else
        [logFeed info:0 inSubsection:subsection withText:@"Test HTTP: received delete request with no headers"];
    
    [req setResponseCode:HTTP_RESPONSE_CODE_OK];
    [req setResponseHeader:@"Connection" withValue:@"keep-alive"]; 
    
    msg2 = [NSString stringWithFormat:@"Test HTTP: sent delete reply headers with content length 0 \r\n"];
    [logFeed debug:0 inSubsection:subsection withText:msg2];
}

@end
