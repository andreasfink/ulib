 //
//  UMTestHTTPClient.m
//  ulib
//
//  Created by Aarno Syvänen on 27.04.12.
//  //  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMTestHTTPClient.h"
#import "UMLogFeed.h"
#import "UMTestHTTP.h"
#import "UMTestHTTPEntity.h"
#import "NSMutableArray+UMHTTP.h"

#include <regex.h>

enum bodyxpectation {
    /*
     * Message must not have a body, even if the headers indicate one.
     * (i.e. response to HEAD method).
     */
    expectNoBody,
    /*
     * Message will have a body if Content-Length or Transfer-Encoding
     * headers are present (i.e. most request methods).
     */
    expectDodyIfIndicated,
    /*
     * Message will have a body, possibly zero-length.
     * (i.e. 200 OK responses to a GET method.)
     */
    expectBody
};

@interface UMTestHTTPClient (PRIVATE)

- (UMSocket *)getSock;
-(void)writeRequestThread;
- (int)sendRequest;
-(BOOL)proxyUsedForHost:(NSString *)host withURL:(NSString *)url;
- (NSString *)buildRequestWithMethod:(NSString *)m withURL:(NSString *)u withHost:(NSString *)h withPort:(long)p withHeaders:(NSMutableArray *)headers withBody:(NSString *)body;
- (void) handleTransaction:( UMTestHTTPClient *)trans;
- (int)parseHTTPVersion:(NSString *)version;
- (int) readStatus;
- (int)responseExpectationWithMethod:(int)m andStatus:(int)s;
- (NSString *)buildResponseWithHeaders:(NSMutableArray *)h andBody:(NSString *)body;
-(NSString *)getRedirectionLocation;
- (void)recoverAbsoluteURLWithLocation:(NSMutableString *)loc;

@end

@implementation UMTestHTTPClient (PRIVATE)

- (UMSocket *)getSock
{
    UMSocket *s = nil;
    NSString *h;
    NSURL *parse;
    int p, SSL;
    NSString *msg;
    
    /* if the parsing has not yet been done, then do it now */
    if (!host && port == 0 && url) 
    {
        parse = [[NSURL alloc]initWithString:url];
        if(parse == NULL)
        {
            goto error;
        }
    }
    
    if ([self proxyUsedForHost:host withURL:url]) 
    {
        h = proxyHostname;
        p = proxyPort;
        SSL = proxySsl;
    } 
    else 
    {
        h = host;
        p = (int)port;
        SSL = ssl;
    }
    
    s = [pool getSocketWith:h withPort:p withSSL:SSL != 0 withCertificate:nil withLocalHost:nil];
    if (!s)
        goto error;
    
    return s;
    
error:
    msg = [NSString stringWithFormat:@"Couldn't send request to <%@>\r\n", url];
    [logFeed minorError:0 inSubsection:subsection withText:msg];
    return nil;
}

- (void)writeRequestThread
{
    int rc;
    UMTestHTTPClient *trans;
    UMSocket *ourSock;

    while (runStatus == running)
    {
        trans = [pendingRequests consume];
        if (!trans)
            break;
                
        if (state != requestNotSent)
            break;
        
        NSString *msg1 = [NSString stringWithFormat:@"UMTestHTTPClient: writeRequestThread: Queue contains %lu pending requests.\r\n", (unsigned long)[pendingRequests count]];
        [logFeed debug:0 inSubsection:subsection withText:msg1];
        
        /*
         * get the socket to use
         * also calls parseURL to populate the corresponding instance variables
         */
        if (!sock)
        {
            ourSock = [self getSock];
            self.sock = ourSock;
        }
        
        if (!sock)
        {
            [caller addObject:trans];
        }
        else if ([sock isConnected]) 
        {
            [logFeed debug:0 inSubsection:subsection withText:@"UMTestHTTPClient: writeRequestThread:Socket connected at once\r\n"];
            trans.sock = sock;
            
            if ((rc = [trans sendRequest]) == 0) 
            {
                self.state = readingStatus;
                [self handleTransaction:trans];
            } 
            else
            {
                [caller addObject:trans];
            }
        } 
        else 
        { /* Socket not connected, wait for connection */
            [logFeed debug:0 inSubsection:subsection withText:@"UMTestHTTPClient: writeRequestThread:Socket connecting\r\n"];
            self.state = connecting;
            [self handleTransaction:trans];
        }
    }
}

-(BOOL)proxyUsedForHost:(NSString *)h withURL:(NSString *)u
{
    int i;
    NSString *exception;
    int ret;
    
    [proxyMutex lock];
    
    if (!proxyHostname) {
        [proxyMutex unlock];
        return FALSE;
    }   
    
    for (i = 0; i < [proxyExceptions count]; ++i) {
        exception = proxyExceptions[i];
        if ([h compare:exception] == NSOrderedSame) {  
            [proxyMutex unlock];
            return FALSE;
        }
    }
    
    if (proxyExceptionsRegex)
    {
        ret = regexec(proxyExceptionsRegex,[u UTF8String], 0, NULL, 0);
        if (ret == 0) 
        {
            [proxyMutex unlock];
            return FALSE;
        }
    }
    
    [proxyMutex unlock];
    return TRUE;
}

- (NSString *)buildRequestWithMethod:(NSString *)m withURL:(NSString *)u withHost:(NSString *)h withPort:(long)p withHeaders:(NSMutableArray *)headers withBody:(NSString *)body
{
    /* XXX headers missing */
    NSMutableString *request;
    int i;
    
    request = [NSMutableString stringWithFormat:@"%@ %@ HTTP/1.1\r\n", m, u];
    
    [request appendFormat:@"Host: %@", h];
    if (p != HTTP_PORT)
        [request appendFormat:@":%ld", p];
    [request appendString:@"\r\n"];
    
    [request appendString:@"Connection: keep-alive\r\n"];
    
    for (i = 0; headers != NULL && i < [headers count]; ++i) {
        [request appendString:headers[i]];
        [request appendString:@"\r\n"];
    }
    [request appendString:@"\r\n"];
    
    if (body)
        [request appendString:body];
    
    return request;
}

/*
 * Build and send the HTTP request. Return 0 for success or -1 for error.
 */
- (int)sendRequest
{
    NSString *request = nil;
    NSString *value;
    NSMutableString *logRequest;
    NSString *logRequestHeaders;
    NSMutableString *logRequestBody;
    NSRange headerEnd;

    logFeed.copyToConsole = 1;
    
    if (method == HTTP_METHOD_POST || method == HTTP_METHOD_PUT) {
        /*
         * Add a Content-Length header.  Override an existing one, if
         * necessary.  We must have an accurate one in order to use the
         * connection for more than a single request.
         */
         [requestHeaders removeAllWithName:@"Content-Length"];
         value = [NSString stringWithFormat:@"%lu",(unsigned long)[requestBody length]];
         [requestHeaders addHeaderWithName:@"Content-Length" andValue:value];  
     }
     /* 
      * ok, this has to be an GET or HEAD request method then,
      * if it contains a body, then this is not HTTP conform, so at
      * least warn the user. For teastinh purposes we add Content-lngth heare. 
      * Even if the cilent should not send GET request with content, the server
      * should accept one.
      */
    else if (requestBody) 
    {
        NSString *msg = [NSString stringWithFormat:@"UMTestHTTPClient: startRequest: GET or HEAD method request contains body: %@\r\n", requestBody];
        [logFeed warning:0 inSubsection:subsection withText:msg];
        
        [requestHeaders removeAllWithName:@"Content-Length"];
        value = [NSString stringWithFormat:@"%lu", (unsigned long)[requestBody length]];
        [requestHeaders addHeaderWithName:@"Content-Length" andValue:value];
    }

    /*
     * we have to assume all values in trans are already set
     * by parse_url() before calling this.
     */

    NSString *methodName = httpMethods[method];
    if ([self proxyUsedForHost:host withURL:url])
    {
        [requestHeaders proxyAddAuthenticationWithUserName:username andPassword:password];
        request = [self buildRequestWithMethod:methodName withURL:url withHost:host withPort:port withHeaders:requestHeaders withBody:requestBody];
    } 
    else 
    {
        request = [self buildRequestWithMethod:methodName withURL:url withHost:host withPort:port withHeaders:requestHeaders withBody:requestBody];
    }
    
    if (request)
    {
        logRequest = [request mutableCopy];
        headerEnd = [logRequest rangeOfString:@"\r\n\r\n"];
        [logRequest replaceOccurrencesOfString:@"\r\n\r\n" withString:@" tend " options:NSCaseInsensitiveSearch range:NSMakeRange(0, headerEnd.location + 4)];
        [logRequest replaceOccurrencesOfString:@"\r\n" withString:@"\n" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [logRequest length])];
        headerEnd = [logRequest rangeOfString:@" tend"];
        [logRequest replaceOccurrencesOfString:@"\n" withString:@" hend " options:NSCaseInsensitiveSearch range:NSMakeRange(0, headerEnd.location)];
        headerEnd = [logRequest rangeOfString:@" tend"];
        [logRequest replaceOccurrencesOfString:@"\n" withString:@" bend " options:NSCaseInsensitiveSearch range:NSMakeRange(headerEnd.location, [logRequest length] - headerEnd.location)];
        headerEnd = [logRequest rangeOfString:@" tend"];
    
        logRequestHeaders = [logRequest substringToIndex:headerEnd.location + 6];
        logRequestBody = [[logRequest substringFromIndex:headerEnd.location + 6] mutableCopy];
        [logRequestBody appendString:@" trend "];
        NSString *msg3 = [NSString stringWithFormat:@"Test HTTP: sent %@ request headers %@ \r\n", methodName, logRequestHeaders];
        [logFeed info:0 inSubsection:subsection withText:msg3];
        NSString *msg4 = [NSString stringWithFormat:@"Test HTTP: sent %@ request body %@ \r\n", methodName, logRequestBody];
        [logFeed info:0 inSubsection:subsection withText:msg4];
    }
    else
    {
        NSString *msg3 = [NSString stringWithFormat:@"sent %@ request with no headers \r\n", methodName];
        [logFeed info:0 inSubsection:subsection withText:msg3];
    }

    NSString *msg1 = [NSString stringWithFormat:@"UMTestHTTPClient: startRequest: sending request %@\r\n", request];
    [logFeed info:0 inSubsection:subsection withText:msg1];

    if ([sock sendString:request] == -1)
        goto error;

    return 0;

error:
    [sock close];
    sock = nil;
    NSString *msg2 = [NSString stringWithFormat:@"UMTestHTTPClient: Couldn't send request to <%@>\r\n", url];
     [logFeed majorError:0 inSubsection:subsection withText:msg2];
    return -1;
}

- (int)parseHTTPVersion:(NSString *)version
{
    NSString *prefix;
    long prefix_len;
    int digit;
    
    prefix = @"HTTP/1.";
    prefix_len = [prefix length];
    
    if ([version compare:prefix options:NSCaseInsensitiveSearch range:NSMakeRange(0, prefix_len)] != NSOrderedSame)
        return -1;
    if ([version length] != prefix_len + 1)
        return -1;
    
    digit = [version characterAtIndex:prefix_len];
    if (!isdigit(digit))
        return -1;
    if (digit == '0')
        return 0;
    return 1;
}

/*
 * Read and parse the status response line from an HTTP server.
 * Fill in trans->persistent and trans->status with the findings.
 * Return -1 for error, 1 for status line not yet available, 0 for OK.
 */
- (int) readStatus
{
    NSMutableData *line;
    NSMutableString *sline;
    NSString *version;
    NSRange space;
    int ret;
    UMSocketError sErr;
    NSString *msg2;
    
try_again:
    sErr = [sock receiveLineTo:&line];
    if (!line) {
        if (sErr != UMSocketError_try_again)
            return -1;
        goto try_again;
    }
    
    sline = [[NSMutableString alloc] initWithData:line encoding:NSASCIIStringEncoding];
    NSString *msg = [NSString stringWithFormat:@"UMTestHTTPClient: readStatus: Status line: <%@>\r\n", sline];
    [logFeed debug:0 inSubsection:subsection withText:msg];
    
    space = [sline rangeOfString:@" "];
    if (space.location == NSNotFound)
        goto error;
    
    version = [sline substringToIndex:space.location];
    ret = [self parseHTTPVersion:version];
    if (ret == -1)
        goto error;
    persistent = ret;
    [sline deleteCharactersInRange:NSMakeRange(0, space.location + 1)];
    
    space = [sline rangeOfString:@" "];
    if (space.location == NSNotFound)
        goto error;
    
    [sline deleteCharactersInRange:NSMakeRange(space.location, [sline length] - space.location)];
    httpStatus = (_httpStatus)[sline integerValue];
    
    return 0;
    
error:
    msg2 = [NSString stringWithFormat:@"UMTestHTTPClient: readStatus: Malformed status line from HTTP server: <%@>\r\n", sline];
    [logFeed minorError:0 inSubsection:subsection withText:msg2];
    return -1;
}

/*
 * This function relies on the HTTP_STATUS_* enum values being
 * chosen to fit this.
 */
- (int)statusClassOf:(int)code
{
    int sclass;
    
    if (code < 100 || code >= 600)
        sclass = HTTP_STATUS_UNKNOWN;
    else
        sclass = code - (code % 100);
    return sclass;
}

- (int)responseExpectationWithMethod:(int)m andStatus:(int)s
{
    if (s == HTTP_NO_CONTENT ||
        s == HTTP_NOT_MODIFIED ||
        [self statusClassOf:httpStatus] == HTTP_STATUS_PROVISIONAL ||
        m == HTTP_METHOD_HEAD)
        return expectNoBody;
    else
        return expectBody;
}

- (NSString *)buildResponseWithHeaders:(NSMutableArray *)h andBody:(NSString *)body
{
    NSMutableString *r;
    int i;
    
    r = [[NSMutableString alloc] init];
    
    for (i = 0; h && i < [h count]; ++i) {
        [r appendString:h[i]];
        [r appendString:@"\r\n"];
    }
    [r appendString:@"\r\n"];
    
    if (body)
        [r appendString:body];
    
    return r;
}

-(NSString *)getRedirectionLocation
{
    if (followRemaining <= 0)
    {
        return nil;
    }
    /* check for the redirection response codes */
    if (httpStatus != (_httpStatus)HTTP_MOVED_PERMANENTLY &&
        httpStatus != (_httpStatus)HTTP_FOUND &&
        httpStatus != (_httpStatus)HTTP_SEE_OTHER &&
        httpStatus != (_httpStatus)HTTP_TEMPORARY_REDIRECT)
        return nil;
    
    if (!response)
        return nil;
    
    return [[response headers] findFirstWithName:@"Location"];
}

/*
 * Recovers a Location header value of format URI /xyz to an
 * absoluteURI format according to the protocol rules.
 * This simply implies that we re-create the prefixed scheme,
 * user/passwd (if any), host and port string and prepend it
 * to the location URI.
 */
- (void)recoverAbsoluteURLWithLocation:(NSMutableString *)loc
{
    NSMutableString *os;
    
    if (!loc)
        return;
    
    /* we'll only accept locations with a leading / */
    if ([loc characterAtIndex:0] == '/') {
        
        /* scheme */
        if (ssl)
            os = [NSMutableString stringWithString:@"https://"];
        else
            os = [NSMutableString stringWithString:@"http://"];
        
        /* credentials, if any */
        if (username && password) {
            [os appendString:username];
            [os appendString:@":"];
            [os appendString:password];
            [os appendString:@"@"];
        }
        
        /* host */
        [os appendString:host];
        
        /* port, only added if literally not default. */
        if (port != 80 || ssl) 
        {
            [os appendFormat:@":%ld", port];
        }
        /* prepend the created octstr to the loc, and destroy then. */
        [loc replaceCharactersInRange:NSMakeRange(0, 0) withString:os];
    }
}

- (void) handleTransaction:(UMTestHTTPClient *)trans
{
    int ret = -1;
    NSString *h, *h1;
    int rc;
    UMTestHTTPEntity *ent;
    
    if (runStatus != running)
    {
        return;
    }
    
    while (state != transactionDone) 
    {
        switch (state)
        {
            case connecting:
                if ([sock isConnected]) 
                {
                    [logFeed debug:0 inSubsection:subsection withText:@"UMTestHTTPClient: handleTransaction: Socket not connected\r\n"];
                    goto error;
                }
                    
                if ((rc = [self sendRequest]) == 0) 
                {
                    self.state = readingStatus;
                } 
                else 
                {
                    [logFeed debug:0 inSubsection:subsection withText:@"UMTestHTTPClient: handleTransaction:Failed while sending request\r\n"];
                    goto error;
                }
                break;
                    
            case readingStatus:
                ret = [self readStatus];
                if (ret < 0)
                {
                    /*
                     * Couldn't read the status from the socket. This may mean
                     * that the socket had been closed by the server after an
                     * idle timeout.
                     */
                    [logFeed debug:0 inSubsection:subsection withText:@"UMTestHTTPClient: handleTransaction: Failed while reading status\r\n"];
                    goto error;
                } 
                else if (ret == 0)
                {
                    /* Got the status, go read headers and body next. */
                    self.state = readingEntity;
                    ent = [[UMTestHTTPEntity alloc] initWithBodyExpectation:[self responseExpectationWithMethod:method andStatus:httpStatus]];
                    self.response = ent;
                } 
                else 
                {
                    return;
                }
                break;
                    
            case readingEntity:
                ret = [response readEntityFrom:sock];
                if (ret < 0) 
                {
                    [logFeed debug:0 inSubsection:subsection withText:@"UMTestHTTPClient: handleTransaction:Failed reading entity\r\n"];
                    goto error;
                } 
                else if (ret == 0 && [self statusClassOf:httpStatus] == HTTP_STATUS_PROVISIONAL)
                {
                    /* This was a provisional reply; get the real one now. */
                    self.state = readingStatus;
                    self.response = nil;
                } 
                else if (ret == 0) 
                {
                    self.state = transactionDone;
#ifdef DUMP_RESPONSE
                    /* Dump the response */
                    h = [self buildResponseWithHeaders:[response headers] andBody:[response body]];
                    NSString *msg = [NSString stringWithFormat:@"UMTestHTTPClient: handleTransaction: Reveived response %@\r\n", h];
                    [logFeed debug:0 inSubsection:subsection withText:msg];
#endif
                } 
                else 
                {
                    return;
                }
                break;
                
            default:
                @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Internal error: Invalid UMTestHTPPClient state." userInfo:nil];
        }
    }
    
    /*
     * Take care of persistent connection handling.
     * At this point we have only obeyed if server responds in HTTP/1.0 or 1.1
     * and have assigned persistent accordingly. This can be kept
     * for default usage, but if we have [Proxy-]Connection: keep-alive, then
     * we're still forcing persistancy of the connection.
     */
    h = [[response headers] findFirstWithName:@"Connection"];
    if (h && [h compare:@"close" options:NSCaseInsensitiveSearch] == NSOrderedSame)
        self.persistent = 0;
    if (h && [h compare:@"keep-alive" options:NSCaseInsensitiveSearch] == NSOrderedSame)
        self.persistent = 1;
    
    if ([self proxyUsedForHost:host withURL:url]) 
    {
        h1 = [[response headers] findFirstWithName:@"Proxy-Connection"];
        if (h1 && [h1 compare:@"close" options:NSCaseInsensitiveSearch] == NSOrderedSame)
            self.persistent = 0;
        if (h1 && [h1 compare:@"keep-alive" options:NSCaseInsensitiveSearch] == NSOrderedSame)
            self.persistent = 1;
    }
    
    if (persistent) 
    {
        if ([self proxyUsedForHost:host withURL:url])
            [pool putSocket:sock withRemoteHost:proxyHostname withPort:proxyPort enableSSL:ssl withCertificate:certkeyFile withLocalHost:httpInterface];
        else
            [pool putSocket:sock withRemoteHost:host withPort:(int)port enableSSL:ssl withCertificate:certkeyFile withLocalHost:httpInterface];
    } 
    else
    {
        [sock close];
    }
    
    sock = nil;
    
    /*
     * Check if the HTTP server told us to look somewhere else,
     * hence if we got one of the following response codes:
     *   HTTP_MOVED_PERMANENTLY (301)
     *   HTTP_FOUND (302)
     *   HTTP_SEE_OTHER (303)
     *   HTTP_TEMPORARY_REDIRECT (307)
     */
     if ((h = [self getRedirectionLocation])) 
     {
         /*
          * This is a redirected response, we have to follow.
          *
          * According to HTTP/1.1 (RFC 2616), section 14.30 any Location
          * header value should be 'absoluteURI', which is defined in
          * RFC 2616, section 3.2.1 General Syntax, and specifically in
          * RFC 2396, section 3 URI Syntactic Components as
          *
          *   absoluteURI   = scheme ":" ( hier_part | opaque_part )
          *
          * Some HTTP servers 'interpret' a leading UDI / as that kind
          * of absoluteURI, which is not correct, following the protocol in
          * detail. But we'll try to recover from that misleaded
          * interpreation and try to convert the partly absoluteURI to a
          * fully qualified absoluteURI.
          *
          *   http_URL = "http:" "//" [ userid : password "@"] host
          *      [ ":" port ] [ abs_path [ "?" query ]]
          *
          */
         [self recoverAbsoluteURLWithLocation:[h mutableCopy]];
         
         /*
          * Clean up all trans stuff for the next request we do.
          */
         self.port = 0;
         self.host = nil;
         self.uri = nil;
         self.username = nil;
         self.password = nil;
         self.ssl = 0;
         self.url = h; /* apply new absolute URL to next request */
         self.state = requestNotSent;
         self.httpStatus = -1;
         self.response = nil;
         --(self.followRemaining);
         [sock close];
         self.sock = nil;
         
         /* re-inject request to the front of the queue */
         [pendingRequests insertObject:self atIndex:0];
     } 
     else 
     {
         /* handle this response as usual */
         trans.response = response;
         trans.httpStatus = httpStatus;
         [caller addObject:trans];
     }
     return;

error:
    [sock close];
    sock = nil;
    NSString *msg = [NSString stringWithFormat:@"UMTestHTTPClient: handleTransaction: Couldn't fetch <%@>\r\n", url];
    [logFeed majorError:0 inSubsection:subsection withText:msg];
    runStatus = terminating;
    [caller addObject:trans];
}

@end

@implementation UMTestHTTPClient

@synthesize sock;
@synthesize caller;
@synthesize requestId;
@synthesize state;
@synthesize httpStatus;
@synthesize runStatus;
@synthesize url;
@synthesize response;
@synthesize pendingRequests;
@synthesize host;
@synthesize port;
@synthesize username;
@synthesize password;
@synthesize method;
@synthesize timeout;
@synthesize certkeyFile;
@synthesize requestBody;
@synthesize proxyUsername;
@synthesize proxyPassword;
@synthesize proxyMutex;
@synthesize sender;
@synthesize proxySsl;
@synthesize proxyHostname;
@synthesize httpMethods;
@synthesize subsection;
@synthesize proxyPort;
@synthesize uri;
@synthesize persistent;
@synthesize requestHeaders;
@synthesize ssl;
@synthesize httpInterface;
@synthesize followRemaining;
@synthesize pool;
@synthesize client_threads_are_running;
@synthesize clientThreadLock;
@synthesize proxyExceptions;


- (UMTestHTTPClient *)init
{
    if((self = [super init]))
    {
        self.pool = nil;
        self.httpMethods = nil;
        self.caller = nil;
        self.requestId = nil;
        self.method = 0;
        self.url = nil;
        self.uri = nil;
        self.requestHeaders = nil;
        self.requestBody = nil;
        self.state = requestNotSent;
        self.httpStatus = -1;
        self.persistent = 0;
        self.response = nil;
        self.sock = nil;
        self.host = NULL;
        self.port = 0;
        self.username = nil;
        self.password = nil;
        self.followRemaining = 0;
        self.certkeyFile = nil;
        self.ssl = 0;
        self.runStatus = limbo;
        self.pendingRequests = nil;
        self.clientThreadLock = nil;
        self.client_threads_are_running = 0;
        self.proxyMutex = nil;
        self.proxyHostname = nil;
        self.proxyPort = 0;
        self.proxySsl = 0;
        self.proxyUsername = nil;
        self.proxyPassword = nil;
        self.proxyExceptions = nil;
        proxyExceptionsRegex = NULL;
    }
    return self;
}

- (UMTestHTTPClient *)initWithCaller:(UMHTTPCaller *)c withMethod:(int)m withURL:(NSString *)u
                         withHeaders:(NSMutableArray *)h withBody:(NSString *)b followRedirections:(int)follow
                     withCertificate:(NSString *)ck
{
    self = [super init];
    if(self)
    {
        self.pool = [[UMConnPool alloc] init];
        self.httpMethods = [[NSArray alloc] initWithObjects:@"GET", @"POST", @"HEAD", @"OPTIONS", @"TRACE", @"PUT", @"DELETE", nil];
        self.caller = c;
        self.requestId = nil;
        self.method = m;
        self.url = u;
        self.uri = nil;
        self.requestHeaders = h;
        self.requestBody = b;
        self.state = requestNotSent;
        self.httpStatus = -1;
        self.persistent = 0;
        self.response = nil;
        self.sock = nil;
        self.host = nil;
        self.port = 0;
        self.username = nil;
        self.password = nil;
        self.followRemaining = follow;
        self.certkeyFile = ck;
        self.ssl = 0;
        self.runStatus = limbo;
        self.pendingRequests = [[TestMutableArray alloc] init];
        self.clientThreadLock = nil;
        self.client_threads_are_running = 0;
        self.proxyMutex = nil;
        self.proxyHostname = nil;
        self.proxyPort = 0;
        self.proxySsl = 0;
        self.proxyUsername = nil;
        self.proxyPassword = nil;
        self.proxyExceptions = nil;
        proxyExceptionsRegex = NULL;
        self.logFeed = [c logFeed];
    }
    return self;
}

- (UMTestHTTPClient *)copySalient
{
    UMTestHTTPEntity *ent = [[UMTestHTTPEntity alloc] init];
    ent.headers = [response headers];
    ent.body = [response body];
    
    UMTestHTTPClient *copy = [[UMTestHTTPClient alloc] init];
    copy.httpStatus = httpStatus;
    copy.url = url;
    copy.response = ent;
    
    return copy;
}

- (NSString *)description
{
    NSMutableString *desc;
    
    desc = [[NSMutableString alloc] initWithString:@"HTTP client dump starts\r\n"];
    [desc appendFormat:@"username was %@\r\n", username ? username : @"not set"];
    [desc appendFormat:@"password was %@\r\n", password ? password : @"not set"];
    [desc appendFormat:@"pending requests were %@\r\n", pendingRequests ? pendingRequests : @"none"];
    [desc appendFormat:@"response was %@\r\n", response ? response :@"none"];
    [desc appendString:@"HTTP client dump ends\r\n"];
    
    return desc;
}

- (void)dealloc
{
    [sock close];
    
    [pendingRequests removeProducer];

    if (proxyExceptionsRegex)
    {
        regfree(proxyExceptionsRegex);
    }
    proxyExceptionsRegex = NULL;
}

- (void)addRequestUnlocked:(UMTestHTTPClient *)req
{
    [pendingRequests addObjectUnlocked:req];
}

- (void)addRequest:(UMTestHTTPClient *)req
{
    [pendingRequests addObject:req];
}

-(void)setClientTimeout:(long)t
{
    self.timeout = t;
}

-(void) startClientThreads
{
    if (!client_threads_are_running) 
    {
        /*
         * To be really certain, we must repeat the test, but use the
         * lock first. If the test failed, however, we _know_ we've
         * already initialized. This strategy of double testing avoids
         * using the lock more than a few times at startup.
         */
        [clientThreadLock lock];
        if (!client_threads_are_running)
        {            
            runStatus = running;
            [self performSelectorInBackground:@selector(writeRequestThread) withObject:nil];
            //sender = [[NSThread alloc] initWithTarget:self
            //                                 selector:@selector(writeRequestThread)
            //                                   object:nil];
            //[sender start];
            
            //if ([sender isExecuting] == FALSE) 
            //{
            //[logFeed majorError:0 inSubsection:subsection withText:@"UMTestHTTPClient: startClientThreads: //Could not start client writeRequestThread.\r\n"];
            //     client_threads_are_running = 0;
                // } else
            client_threads_are_running = 1;
        }
        [clientThreadLock unlock];
    }
}

-(void)useProxyWithHost:(NSString *)hostname
               withPort:(int)p
              enableSSL:(BOOL)SSL
         withExceptions:(NSMutableArray *)exceptions
           withUsername:(NSString *)u
           withPassword:(NSString *)pass
    withRegexExceptions:(NSString *)exceptionsRegex
{
    NSString *e;
    int i;
    NSString *msg, *msg1, *msg2;
    int rc;
    regex_t *preg = nil;
    
    if (runStatus != running)
        return;
    
    if (!hostname)
        return;
    
    if ([hostname length] == 0)
        return;

    if (port <= 0)
        return;
    
    [self closeProxy];
    [proxyMutex lock];
    
    self.proxyHostname = hostname;
    self.proxyPort = p;
    self.proxySsl = SSL;
    self.proxyExceptions = [[NSMutableArray alloc] init];
    for (i = 0; i < [exceptions count]; ++i) 
    {
        e = exceptions[i];
        msg = [NSString stringWithFormat:@"UMTestHTTPClient: useProxy: Proxy exception `%@'\r\n.", e];
        [logFeed debug:0 inSubsection:subsection withText:msg];
        [proxyExceptions addObject:[e copy]];
    }
    
    if (exceptionsRegex)
    {
        preg = malloc(sizeof(regex_t));
        rc = regcomp(preg, exceptionsRegex ? [exceptionsRegex UTF8String] : NULL,REG_EXTENDED);
        if (rc != 0)
        {
            msg1 = [NSString stringWithFormat:@"Could not compile pattern '%@'", exceptionsRegex];
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:msg1 userInfo:nil];
        }
    }
    proxyExceptionsRegex = preg;
    
    self.proxyUsername = [u copy];
    self.proxyPassword = [pass copy];
    msg2 = [NSString stringWithFormat:@"UMTestHTTPClient: useProxy: Using proxy <%@:%d> with %@ scheme\r\n", proxyHostname,
            proxyPort, proxySsl ? @"HTTPS" : @"HTTP"];
    [logFeed debug:0 inSubsection:subsection withText:msg2];
    
    [proxyMutex unlock];
}

-(void)closeProxy
{
    if (runStatus != running && runStatus != terminating)
        return;
    
    [proxyMutex lock];
    self.proxyPort = 0;
    self.proxyHostname = nil;
    self.proxyUsername = nil;
    self.proxyPassword = nil;
    regfree(proxyExceptionsRegex);
    self.proxyExceptions = nil;
    proxyExceptionsRegex = NULL;
    [proxyMutex unlock];
}

- (UMTestHTTPClient *) startRequestWithMethod:(int)m
                                   withCaller:(UMHTTPCaller *)c
                                      withURL:(NSString *)u
                                  withHeaders:(NSMutableArray *)hdrs
                                     withBody:(NSString *)b
                           followRedirections:(int) follow
                                       withId:(void *)hid
                              withCertificate:(NSString *)ck
                                     withHost:(NSString *)h
                                     withPort:(long)p
                                 withUsername:(NSString *)user
                                 withPassword:(NSString *)pass
{
    int follow_remaining;
   
    if (follow)
    {
        follow_remaining = HTTP_MAX_FOLLOW;
    }
    else
    {
        follow_remaining = 0;
    }
    
    self.httpMethods = [[NSArray alloc] initWithObjects:@"GET", @"POST", @"HEAD", @"OPTIONS", @"TRACE", @"PUT", @"DELETE", nil];
    self.url = u;
    self.method = m;
    self.requestHeaders = hdrs;
    self.requestBody = b;
    
    UMTestHTTPClient *client = [[UMTestHTTPClient alloc] initWithCaller:c
                                          withMethod:m
                                             withURL:u
                                         withHeaders:hdrs 
                                            withBody:b
                                  followRedirections:follow
                                     withCertificate:ck];
    if(client)
    {
    
        if (!hid)
        /* We don't leave this nil so receiveResult can use nil
        * to signal no more requests */
            self.requestId = client.requestId = (void *)-1;
        else
            self.requestId = client.requestId = hid;
    
        self.runStatus = client.runStatus = running;
        self.host = client.host = h;
        self.port = client.port = p;
        self.timeout = client.timeout = 100;
        self.username = client.username = user;
        self.password = client.password = pass;
        [self addRequest:self];
        [client addRequest:client];
        [client startClientThreads];
    }
    return client;
}

-(void *)receiveResultReturningStatus:(int *)s URL:(NSString **)finalURL headers:(NSMutableArray **)headers body:(NSString **)body doBlock:(BOOL)blocking
{
    UMTestHTTPClient *trans;
    void *rid;
    
    if (blocking == FALSE)
        trans = [caller objectAtIndex:0];
    else
        trans = [caller consume];
    if (!trans)
        return nil;
    
    rid = [trans requestId];
    *s = [trans httpStatus];
    
    if (s >= 0)
    {
        *finalURL = [trans url];
        *headers = [[trans response] headers];
        *body = [[NSString alloc] initWithData:[[trans response] body] encoding:NSUTF8StringEncoding];
        [[trans response] setHeaders:nil];
        [[trans response] setBody:nil];
        [trans setUrl:nil];
    }
    else 
    {
        *finalURL = nil;
        *headers = nil;
        *body = nil;
    }
    
    return rid;
}

@end
