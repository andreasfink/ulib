//
//  TestUMHTTPServer.m
//  ulib
//
//  Created by Aarno Syvänen on 25.04.12.
//  //  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "TestUMHTTPServer.h"
#import "UMTestHTTP.h"
#import "UMConfig.h"
#import "UMTestCase.h"
#import "UMTestHTTPClient.h"
#import "UMTestDelegate.h"
#import "NSMutableData+UMTestString.h"
#import "NSMutableString+UMTestString.h"
#import "NSMutableArray+UMHTTP.h"
#import "UMLogFile.h"
#import "UMLogFeed.h"
#import "UMutil.h"

#include <unistd.h>

@implementation TestUMHTTPServer

- (void)setUp
{
    [super setUp];
    NSString *projectRoot = [NSString stringWithFormat:@"%s/../../..",
                             getenv("__XCODE_BUILT_PRODUCTS_DIR_PATHS")];
    chdir(projectRoot.UTF8String);
}

- (void)tearDown
{
    // Tear-down code here.
    [super tearDown];
}

+ (NSString *)methodToString:(int)method
{
    switch(method)
    {
        case HTTP_METHOD_GET:
            return @"get";
        case HTTP_METHOD_POST:
            return @"post";
        case HTTP_METHOD_HEAD:
            return @"head";
        case HTTP_METHOD_OPTIONS:
            return @"options";
        case HTTP_METHOD_TRACE:
            return @"trace";
        case HTTP_METHOD_PUT:
            return @"put";
        case HTTP_METHOD_DELETE:
            return @"delete";
    }
    
    return @"N.N";
}

+ (void) messagesInLogFile:(UMLogFile *)dst sent:(NSMutableDictionary **)sentMessages received:(NSMutableDictionary **)receivedMessages messagesSent:(long *)numberOfSent messagesReceived:(long *)numberOfReceived contentsSent:(long *)numberOfContentsSent contentsReceived:(long *)numberOfContentsReceived;
{
    NSArray *types, *clientHeaders, *serverHeaders;
    int ret;
    NSString *line;
    long i, j;
    NSRange client, test, server, get, type, request, reply, serverReplyHeaders, clientReplyHeaders, serverRequestHeaders, clientRequestHeaders, contentType, charset, contentLength, start, end, versionData, hend;
    NSString *item;
    NSRange space;
    NSString *contentTypeValue, *charsetValue, *contentLengthValue, *clientHeadersString, *serverHeadersString;
    NSMutableString *contentValue;
    NSUInteger len, hlen, nameLen;
    NSMutableString *header;
    NSString *name, *index;
    NSMutableString *value;
    NSArray *requestHeaders;
    ssize_t size;
    NSString *clientMethodLine;
    NSArray *clientParams;
    NSMutableString *urlValue, *versionValue;
        
    *sentMessages = [NSMutableDictionary dictionary];
    *receivedMessages = [NSMutableDictionary dictionary];
    *numberOfSent = 0;
    *numberOfReceived = 0;
    *numberOfContentsSent = 0;
    *numberOfContentsReceived = 0;
    
    types = @[@"get content"];
    requestHeaders = @[@"Accept", @"Accept-Encoding", @"Accept-Language", @"Authorization", @"Connection", @"Host", @"User-Agent"];
    hlen = [requestHeaders count];
    size = [dst updateFileSize];
    if (size == -1)
        return; 
    
    ret = 1;
    while(ret == 1)
    {
        line = [dst readLine:&ret];
        if(ret != 1)
        {
            continue;
        }
        NSLog(@"%@", line);
        test = [line rangeOfString:@"Test HTTP"];
        get = [line rangeOfString:@"get" options:NSCaseInsensitiveSearch];
        client = [line rangeOfString:@"sent content"];
        server = [line rangeOfString:@"received get content"];
        clientReplyHeaders = [line rangeOfString:@"received get reply headers"  options:NSCaseInsensitiveSearch];
        serverReplyHeaders = [line rangeOfString:@"sent get reply headers"  options:NSCaseInsensitiveSearch];
        clientRequestHeaders = [line rangeOfString:@"sent get request headers"  options:NSCaseInsensitiveSearch];
        serverRequestHeaders = [line rangeOfString:@"received get request headers" options:NSCaseInsensitiveSearch];
        request = [line rangeOfString:@"Started request"];
        reply = [line rangeOfString:@"Done with request"];
        contentType = [line rangeOfString:@"content type"];
        charset = [line rangeOfString:@"charset"];
        contentLength = [line rangeOfString:@"content length"];
                
        if (test.location == NSNotFound)
            continue;
        
        if (request.location != NSNotFound)
        {
            (*sentMessages)[@"request done"] = @"has";
            ++*numberOfSent;
        }
        
        if (reply.location != NSNotFound)
        {
            (*receivedMessages)[@"reply received"] = @"has";
            ++*numberOfReceived;
        }
        
        if (get.location != NSNotFound)
        {
            if (client.location != NSNotFound)
            {
                ++*numberOfContentsSent;
                (*sentMessages)[@"client get"] = @"has";
                contentValue = [[line substringWithRange:NSMakeRange(client.location + 13, [line length] - client.location - 13)] mutableCopy];
                [contentValue replaceOccurrencesOfString:@"via get" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [contentValue length])];                
                [contentValue stripBlanks];
                (*sentMessages)[@"content"] = contentValue;
            }
            else if (server.location != NSNotFound)
            {
                ++*numberOfContentsReceived;
                (*receivedMessages)[@"server get"] = @"has";
                contentValue = [[line substringWithRange:NSMakeRange(server.location + 21, [line length] - server.location - 21)] mutableCopy];
                [contentValue stripBlanks];
                (*receivedMessages)[@"content"] = contentValue;
            }
            else if (clientReplyHeaders.location != NSNotFound)
            {
                (*sentMessages)[@"client reply headers"] = @"has";
                if (contentType.location != NSNotFound)
                {
                    space = [line rangeOfString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(contentType.location + 13, [line length] - contentType.location - 13)];
                    if (space.location != NSNotFound)
                    {
                        contentTypeValue = [line substringWithRange:NSMakeRange(contentType.location + 13, space.location - contentType.location - 13)];
                        (*sentMessages)[@"content type"] = contentTypeValue;
                    }
                }
                if (charset.location != NSNotFound)
                {
                    space = [line rangeOfString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(charset.location + 8, [line length] - charset.location - 8)];
                    if (space.location != NSNotFound)
                    {
                        charsetValue = [line substringWithRange:NSMakeRange(charset.location + 8, space.location - charset.location - 8)];
                        (*sentMessages)[@"charset"] = charsetValue;
                    }
                }
                if (contentLength.location != NSNotFound)
                {
                    space = [line rangeOfString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(contentLength.location + 15, [line length] - contentLength.location - 15)];
                    if (space.location != NSNotFound)
                    {
                        contentLengthValue = [line substringWithRange:NSMakeRange(contentLength.location + 15, space.location - contentLength.location - 15)];
                        (*sentMessages)[@"content length"] = contentLengthValue;
                    }
                }
            }
            else if (serverReplyHeaders.location != NSNotFound)
            {
                (*receivedMessages)[@"server reply headers"] = @"has";
                if (contentType.location != NSNotFound)
                {
                    space = [line rangeOfString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(contentType.location + 13, [line length] - contentType.location - 13)];
                    if (space.location != NSNotFound)
                    {
                        contentTypeValue = [line substringWithRange:NSMakeRange(contentType.location + 13, space.location - contentType.location - 13)];
                        (*receivedMessages)[@"content type"] = contentTypeValue;
                    }
                }
                if (charset.location != NSNotFound)
                {
                    space = [line rangeOfString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(charset.location + 8, [line length] - charset.location - 8)];
                    if (space.location != NSNotFound)
                    {
                        charsetValue = [line substringWithRange:NSMakeRange(charset.location + 8, space.location - charset.location - 8)];
                        (*receivedMessages)[@"charset"] = charsetValue;
                    }
                }
                if (contentLength.location != NSNotFound)
                {
                    space = [line rangeOfString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(contentLength.location + 15, [line length] - contentLength.location - 15)];
                    if (space.location != NSNotFound)
                    {
                        contentLengthValue = [line substringWithRange:NSMakeRange(contentLength.location + 15, space.location - contentLength.location - 15)];
                        (*receivedMessages)[@"content length"] = contentLengthValue;
                    }
                }
            }
            else if (clientRequestHeaders.location != NSNotFound)
            {
                (*sentMessages)[@"client request headers"] = @"has";
                start = [line rangeOfString:@"GET" options:NSCaseInsensitiveSearch range:NSMakeRange(clientRequestHeaders.location + 24, [line length] - clientRequestHeaders.location - 24)];
                end = [line rangeOfString:@" tend " options:NSCaseInsensitiveSearch range:NSMakeRange(start.location, [line length] - start.location)];
                clientHeadersString = [line substringWithRange:NSMakeRange(start.location, end.location - start.location)];
                clientHeaders = [clientHeadersString componentsSeparatedByString:@" hend "];
                
                clientMethodLine = clientHeaders[0];
                clientParams = [clientMethodLine componentsSeparatedByString:@" "];
                (*sentMessages)[@"url"] = clientParams[1];
                (*sentMessages)[@"version"] = clientParams[2];
                
                i = 1;
                len = [clientHeaders count];
                while (i < len)
                {
                    header = [clientHeaders[i] mutableCopy];
                    [header stripBlanks];
                    j = 0;
                    while (j < hlen)
                    {
                        name = requestHeaders[j];
                        if ([NSMutableArray nameOf:header is:name])
                        {
                            index = [NSString stringWithFormat:@"client%@", name];
                            nameLen = [name length];
                            value = [[header substringWithRange:NSMakeRange(nameLen + 1, [header length] - nameLen - 1)] mutableCopy];
                            [value stripBlanks];
                            (*sentMessages)[index] = value;
                            break;
                        }
                        ++j;
                    }
                    ++i;
                }
                
            }
            else if (serverRequestHeaders.location != NSNotFound)
            {
                (*receivedMessages)[@"server request headers"] = @"has";
                hend = [line rangeOfString:@" tend" options:NSCaseInsensitiveSearch range:NSMakeRange(serverRequestHeaders.location, [line length] - serverRequestHeaders.location)];
                serverHeadersString = [line substringWithRange:NSMakeRange(serverRequestHeaders.location + 29, hend.location - serverRequestHeaders.location - 29 - 5)];
                serverHeaders = [serverHeadersString componentsSeparatedByString:@" hend "];
                
                i = 0;
                len = [serverHeaders count];
                while (i < len)
                {
                    header = [serverHeaders[i] mutableCopy];
                    [header stripBlanks];
                    j = 0;
                    hlen = [requestHeaders count];
                    while (j < hlen)
                    {
                        name = requestHeaders[j];
                        if ([NSMutableArray nameOf:header is:name])
                        {
                            index = [NSString stringWithFormat:@"server%@", name];
                            nameLen = [name length];
                            value = [[header substringFromIndex:nameLen + 1] mutableCopy];
                            [value stripBlanks];
                            (*receivedMessages)[index] = value;
                            break;
                        }
                        ++j;
                    }
                    ++i;
                }
                
                end = [line rangeOfString:@" fend" options:NSCaseInsensitiveSearch range:NSMakeRange(hend.location, [line length] - hend.location)];
                versionData = [line rangeOfString:@"and version" options:NSCaseInsensitiveSearch range:NSMakeRange(hend.location, end.location - hend.location)];
                urlValue = [[line substringWithRange:NSMakeRange(hend.location + 15, versionData.location - hend.location - 15)] mutableCopy];
               [urlValue stripBlanks];
               (*receivedMessages)[@"url"] = urlValue;
                versionValue = [[line substringWithRange:NSMakeRange(versionData.location + 11, end.location - versionData.location - 11)] mutableCopy];
               [versionValue stripBlanks];
               (*receivedMessages)[@"version"] = versionValue;
            }
        }
        
        i = 0;
        for(item in types)
        {
            type = [line rangeOfString:item];
            if (type.location != NSNotFound)
            {
                if (client.location != NSNotFound)
                    (*sentMessages)[item] = @"has";
                if (server.location != NSNotFound)
                    (*receivedMessages)[item] = @"has";
            }
        }
    }
}

+ (void) postMessagesInLogFile:(UMLogFile *)dst sent:(NSMutableDictionary **)sentMessages received:(NSMutableDictionary **)receivedMessages messagesSent:(long *)numberOfSent messagesReceived:(long *)numberOfReceived contentsSent:(long *)numberOfContentsSent contentsReceived:(long *)numberOfContentsReceived;
{
    NSArray *types, *clientHeaders, *serverHeaders;
    int ret;
    NSString *line;
    long i, j;
    NSRange client, test, server, post, type, request, reply, serverReplyHeaders, clientReplyHeaders, serverRequestHeaders, clientRequestHeaders, contentType, charset, contentLength, start, end, clientRequestBody, serverRequestBody, bend;
    NSString *item;
    NSRange space;
    NSString *contentTypeValue, *charsetValue, *contentLengthValue, *clientString, *clientBody, *clientHeadersString, *serverHeadersString;
    NSMutableString *contentValue;
    NSUInteger len, hlen, nameLen;
    NSMutableString *header;
    NSString *name, *index;
    NSMutableString *value;
    NSArray *requestHeaders;
    NSArray *requestData;
    long size;
    
    *sentMessages = [NSMutableDictionary dictionary];
    *receivedMessages = [NSMutableDictionary dictionary];
    *numberOfSent = 0;
    *numberOfReceived = 0;
    *numberOfContentsSent = 0;
    *numberOfContentsReceived = 0;
    
    types = @[@"get content"];
    requestHeaders = @[@"Accept", @"Accept-Encoding", @"Accept-Language", @"User-Agent", @"Authorization", @"Connection", @"Content-Type", @"Content-Length"];
    hlen = [requestHeaders count];
    size = [dst updateFileSize];
    if (size == -1)
        return;
    
    ret = 1;
    while(ret == 1)
    {
        line = [dst readLine:&ret];
        if(ret != 1)
        {
            continue;
        }
        NSLog(@"%@", line);
        
        test = [line rangeOfString:@"Test HTTP"];
        post = [line rangeOfString:@"post" options:NSCaseInsensitiveSearch];
        client = [line rangeOfString:@"sent content"];
        clientReplyHeaders = [line rangeOfString:@"received post reply headers"  options:NSCaseInsensitiveSearch];
        serverReplyHeaders = [line rangeOfString:@"sent post reply headers"  options:NSCaseInsensitiveSearch];
        clientRequestHeaders = [line rangeOfString:@"sent post request headers"  options:NSCaseInsensitiveSearch];
        serverRequestHeaders = [line rangeOfString:@"received post request headers"  options:NSCaseInsensitiveSearch];
        clientRequestBody = [line rangeOfString:@"sent post request body"  options:NSCaseInsensitiveSearch];
        serverRequestBody = [line rangeOfString:@"received post request body"  options:NSCaseInsensitiveSearch];
        request = [line rangeOfString:@"Started request"];
        reply = [line rangeOfString:@"Done with request"];
        contentType = [line rangeOfString:@"content type"];
        charset = [line rangeOfString:@"charset"];
        contentLength = [line rangeOfString:@"content length"];
        
        if (test.location == NSNotFound)
            continue;
        
        if (request.location != NSNotFound)
        {
            (*sentMessages)[@"request done"] = @"has";
            ++*numberOfSent;
        }
        
        if (reply.location != NSNotFound)
        {
            (*receivedMessages)[@"reply received"] = @"has";
            ++*numberOfReceived;
        }
        
        if (post.location != NSNotFound)
        {
            if (client.location != NSNotFound)
            {
                ++*numberOfContentsSent;
                (*sentMessages)[@"client post"] = @"has";
                contentValue = [[line substringWithRange:NSMakeRange(client.location + 13, [line length] - client.location - 13)] mutableCopy];
                [contentValue replaceOccurrencesOfString:@"via post" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [contentValue length])];
                [contentValue stripBlanks];
                (*sentMessages)[@"content"] = contentValue;
            }
            else if (clientReplyHeaders.location != NSNotFound)
            {
                (*sentMessages)[@"client reply headers"] = @"has";
                if (contentType.location != NSNotFound)
                {
                    space = [line rangeOfString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(contentType.location + 13, [line length] - contentType.location - 13)];
                    if (space.location != NSNotFound)
                    {
                        contentTypeValue = [line substringWithRange:NSMakeRange(contentType.location + 13, space.location - contentType.location - 13)];
                        (*sentMessages)[@"content type"] = contentTypeValue;
                    }
                }
                if (charset.location != NSNotFound)
                {
                    space = [line rangeOfString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(charset.location + 8, [line length] - charset.location - 8)];
                    if (space.location != NSNotFound)
                    {
                        charsetValue = [line substringWithRange:NSMakeRange(charset.location + 8, space.location - charset.location - 8)];
                        (*sentMessages)[@"charset"] = charsetValue;
                    }
                }
                if (contentLength.location != NSNotFound)
                {
                    space = [line rangeOfString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(contentLength.location + 15, [line length] - contentLength.location - 15)];
                    if (space.location != NSNotFound)
                    {
                        contentLengthValue = [line substringWithRange:NSMakeRange(contentLength.location + 15, space.location - contentLength.location - 15)];
                        (*sentMessages)[@"content length"] = contentLengthValue;
                    }
                }
            }
            else if (serverReplyHeaders.location != NSNotFound)
            {
                (*receivedMessages)[@"server reply headers"] = @"has";
                if (contentType.location != NSNotFound)
                {
                    space = [line rangeOfString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(contentType.location + 13, [line length] - contentType.location - 13)];
                    if (space.location != NSNotFound)
                    {
                        contentTypeValue = [line substringWithRange:NSMakeRange(contentType.location + 13, space.location - contentType.location - 13)];
                        (*receivedMessages)[@"content type"] = contentTypeValue;
                    }
                }
                if (charset.location != NSNotFound)
                {
                    space = [line rangeOfString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(charset.location + 8, [line length] - charset.location - 8)];
                    if (space.location != NSNotFound)
                    {
                        charsetValue = [line substringWithRange:NSMakeRange(charset.location + 8, space.location - charset.location - 8)];
                        (*receivedMessages)[@"charset"] = charsetValue;
                    }
                }
                if (contentLength.location != NSNotFound)
                {
                    space = [line rangeOfString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(contentLength.location + 15, [line length] - contentLength.location - 15)];
                    if (space.location != NSNotFound)
                    {
                        contentLengthValue = [line substringWithRange:NSMakeRange(contentLength.location + 15, space.location - contentLength.location - 15)];
                        (*receivedMessages)[@"content length"] = contentLengthValue;
                    }
                }
            }
            else if (clientRequestHeaders.location != NSNotFound)
            {
                (*sentMessages)[@"client request headers"] = @"has";
                start = [line rangeOfString:@"POST" options:NSCaseInsensitiveSearch range:NSMakeRange(clientRequestHeaders.location + 24, [line length] - clientRequestHeaders.location - 24)];
                end = [line rangeOfString:@" tend " options:NSCaseInsensitiveSearch range:NSMakeRange(start.location, [line length] - start.location)];
                clientHeadersString = [line substringWithRange:NSMakeRange(start.location, end.location - start.location)];
                clientHeaders = [clientHeadersString componentsSeparatedByString:@" hend "];
                
                i = 0;
                len = [clientHeaders count];
                while (i < len)
                {
                    header = [clientHeaders[i] mutableCopy];
                    [header stripBlanks];
                    j = 0;
                    while (j < hlen)
                    {
                        name = requestHeaders[j];
                        if ([NSMutableArray nameOf:header is:name])
                        {
                            index = [NSString stringWithFormat:@"client%@", name];
                            nameLen = [name length];
                            value = [[header substringWithRange:NSMakeRange(nameLen + 1, [header length] - nameLen - 1)] mutableCopy];
                            [value stripBlanks];
                            (*sentMessages)[index] = value;
                            break;
                        }
                        ++j;
                    }
                    ++i;
                }
                
            }
            else if (serverRequestHeaders.location != NSNotFound)
            {
                (*receivedMessages)[@"server request headers"] = @"has";
                end = [line rangeOfString:@" tend " options:NSCaseInsensitiveSearch range:NSMakeRange(serverRequestHeaders.location, [line length] - serverRequestHeaders.location)];
                serverHeadersString = [line substringWithRange:NSMakeRange(serverRequestHeaders.location + 29, end.location - serverRequestHeaders.location - 29)];
                serverHeaders = [serverHeadersString componentsSeparatedByString:@" hend "];
                
                i = 0;
                len = [serverHeaders count];
                while (i < len)
                {
                    header = [serverHeaders[i] mutableCopy];
                    [header stripBlanks];
                    j = 0;
                    while (j < hlen)
                    {
                        name = requestHeaders[j];
                        if ([NSMutableArray nameOf:header is:name])
                        {
                            index = [NSString stringWithFormat:@"server%@", name];
                            nameLen = [name length];
                            value = [[header substringWithRange:NSMakeRange(nameLen + 1, [header length] - nameLen - 1)] mutableCopy];
                            [value stripBlanks];
                            (*receivedMessages)[index] = value;
                            break;
                        }
                        ++j;
                    }
                    ++i;
                }
            }
            else if (clientRequestBody.location != NSNotFound)
            {
                (*sentMessages)[@"client request body"] = @"has";
                bend = [line rangeOfString:@" trend " options:NSCaseInsensitiveSearch range:NSMakeRange(clientRequestBody.location, [line length] - clientRequestBody.location)];
                clientString = [line substringWithRange:NSMakeRange(clientRequestBody.location + 22, bend.location - clientRequestBody.location - 22)];
                requestData = [clientString componentsSeparatedByString:@" bend "];
                
                i = 0;
                len = [requestData count];
                while (i < len - 1)
                {
                    header = [requestData[i] mutableCopy];
                    [header stripBlanks];
                    j = 0;
                    while (j < hlen)
                    {
                        name = requestHeaders[j];
                        if ([NSMutableArray nameOf:header is:name])
                        {
                            index = [NSString stringWithFormat:@"clientbody%@", name];
                            nameLen = [name length];
                            value = [[header substringWithRange:NSMakeRange(nameLen + 1, [header length] - nameLen - 1)] mutableCopy];
                            [value stripBlanks];
                            (*sentMessages)[index] = value;
                            break;
                        }
                        ++j;
                    }
                    ++i;
                }
                
                clientBody = requestData[len - 1];
                (*sentMessages)[@"clientbody"] = clientBody;
           }
           else if (serverRequestBody.location != NSNotFound)
           {
               ++*numberOfContentsReceived;
               (*receivedMessages)[@"server post"] = @"has";
               contentValue = [[line substringWithRange:NSMakeRange(serverRequestBody.location + 26, [line length] - serverRequestBody.location - 26)] mutableCopy];
               [contentValue replaceOccurrencesOfString:@"trend" withString:@"" options:NSLiteralSearch  range:NSMakeRange(0, [contentValue length])];
               [contentValue stripBlanks];
               (*receivedMessages)[@"content"] = contentValue;
           }
        }
        
        i = 0;
        for(item in types)
        {
            type = [line rangeOfString:item];
            if (type.location != NSNotFound)
            {
                if (client.location != NSNotFound)
                    (*sentMessages)[item] = @"has";
                if (server.location != NSNotFound)
                    (*receivedMessages)[item] = @"has";
            }
        }
    }
}


+ (void)configHTTPServerWithPort:(long *)port andLogFile:(NSString **)logFile
{
    NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
    NSString *cfgName = [thisBundle pathForResource:@"http-server" ofType:@"conf"];

    UMConfig *cfg = [[UMConfig alloc] initWithFileName:cfgName];
    [cfg allowSingleGroup:@"core"];
    [cfg allowSingleGroup:@"auth"];
    [cfg read]; 
    
    NSDictionary *grp = [cfg getSingleGroup:@"core"];
    if (!grp)
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"configuration file must have group core" userInfo:@{@"backtrace": UMBacktrace(NULL,0) }];
    }
    *port = [grp[@"port"] integerValue];
    *logFile = grp[@"log-file"];
}

+ (void) headMessagesInLogFile:(UMLogFile *)dst sent:(NSMutableDictionary **)sentMessages received:(NSMutableDictionary **)receivedMessages messagesSent:(long *)numberOfSent messagesReceived:(long *)numberOfReceived
{
    NSArray *types, *clientHeaders, *serverHeaders;
    int ret;
    NSString *line;
    long i, j;
    NSRange client, test, server, head, type, request, reply, serverReplyHeaders, clientReplyHeaders, serverRequestHeaders, clientRequestHeaders, contentType, charset, contentLength, start, end, hend, tend;
    NSString *item;
    NSRange space;
    NSString *contentTypeValue, *charsetValue, *contentLengthValue, *clientHeadersString, *serverHeadersString;
    NSUInteger len, hlen, nameLen;
    NSMutableString *header;
    NSString *name, *index;
    NSMutableString *value;
    NSArray *requestHeaders;
    long size;
    NSString *clientMethodLine;
    NSArray *clientParams;
    
    *sentMessages = [NSMutableDictionary dictionary];
    *receivedMessages = [NSMutableDictionary dictionary];
    *numberOfSent = 0;
    *numberOfReceived = 0;
    
    types = @[@"head content"];
    requestHeaders = @[@"Accept", @"Accept-Encoding", @"Accept-Language", @"Authorization", @"Connection", @"Host", @"User-Agent"];
    hlen = [requestHeaders count];
    size = (ssize_t)[dst updateFileSize];
    if (size == -1)
        return;
    
    ret = 1;
    while(ret == 1)
    {
        line = [dst readLine:&ret];
        if(ret != 1)
            continue;
        NSLog(@"%@", line);
        test = [line rangeOfString:@"Test HTTP"];
        head = [line rangeOfString:@"head" options:NSCaseInsensitiveSearch];
        clientReplyHeaders = [line rangeOfString:@"received head reply headers"  options:NSCaseInsensitiveSearch];
        serverReplyHeaders = [line rangeOfString:@"sent head reply headers"  options:NSCaseInsensitiveSearch];
        clientRequestHeaders = [line rangeOfString:@"sent head request headers"  options:NSCaseInsensitiveSearch];
        serverRequestHeaders = [line rangeOfString:@"received head request headers"  options:NSCaseInsensitiveSearch];
        request = [line rangeOfString:@"Started request"];
        reply = [line rangeOfString:@"Done with request"];
        contentType = [line rangeOfString:@"content type"];
        charset = [line rangeOfString:@"charset"];
        contentLength = [line rangeOfString:@"content length"];
        
        if (test.location == NSNotFound)
            continue;
        
        if (request.location != NSNotFound)
        {
            (*sentMessages)[@"request done"] = @"has";
            ++*numberOfSent;
        }
        
        if (reply.location != NSNotFound)
        {
            (*receivedMessages)[@"reply received"] = @"has";
            ++*numberOfReceived;
        }
        
        if (head.location != NSNotFound)
        {
            if (clientReplyHeaders.location != NSNotFound)
            {
                (*sentMessages)[@"client reply headers"] = @"has";
                if (contentType.location != NSNotFound)
                {
                    space = [line rangeOfString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(contentType.location + 13, [line length] - contentType.location - 13)];
                    if (space.location != NSNotFound)
                    {
                        contentTypeValue = [line substringWithRange:NSMakeRange(contentType.location + 13, space.location - contentType.location - 13)];
                        (*sentMessages)[@"content type"] = contentTypeValue;
                    }
                }
                if (charset.location != NSNotFound)
                {
                    space = [line rangeOfString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(charset.location + 8, [line length] - charset.location - 8)];
                    if (space.location != NSNotFound)
                    {
                        charsetValue = [line substringWithRange:NSMakeRange(charset.location + 8, space.location - charset.location - 8)];
                        (*sentMessages)[@"charset"] = charsetValue;
                    }
                }
                if (contentLength.location != NSNotFound)
                {
                    space = [line rangeOfString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(contentLength.location + 15, [line length] - contentLength.location - 15)];
                    if (space.location != NSNotFound)
                    {
                        contentLengthValue = [line substringWithRange:NSMakeRange(contentLength.location + 15, space.location - contentLength.location - 15)];
                        (*sentMessages)[@"content length"] = contentLengthValue;
                    }
                }
            }
            else if (serverReplyHeaders.location != NSNotFound)
            {
                (*receivedMessages)[@"server reply headers"] = @"has";
                if (contentType.location != NSNotFound)
                {
                    space = [line rangeOfString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(contentType.location + 13, [line length] - contentType.location - 13)];
                    if (space.location != NSNotFound)
                    {
                        contentTypeValue = [line substringWithRange:NSMakeRange(contentType.location + 13, space.location - contentType.location - 13)];
                        (*receivedMessages)[@"content type"] = contentTypeValue;
                    }
                }
                if (charset.location != NSNotFound)
                {
                    space = [line rangeOfString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(charset.location + 8, [line length] - charset.location - 8)];
                    if (space.location != NSNotFound)
                    {
                        charsetValue = [line substringWithRange:NSMakeRange(charset.location + 8, space.location - charset.location - 8)];
                        (*receivedMessages)[@"charset"] = charsetValue;
                    }
                }
                if (contentLength.location != NSNotFound)
                {
                    space = [line rangeOfString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(contentLength.location + 15, [line length] - contentLength.location - 15)];
                    if (space.location != NSNotFound)
                    {
                        contentLengthValue = [line substringWithRange:NSMakeRange(contentLength.location + 15, space.location - contentLength.location - 15)];
                        (*receivedMessages)[@"content length"] = contentLengthValue;
                    }
                }
            }
            else if (clientRequestHeaders.location != NSNotFound)
            {
                (*sentMessages)[@"client request headers"] = @"has";
                start = [line rangeOfString:@"HEAD" options:NSCaseInsensitiveSearch range:NSMakeRange(clientRequestHeaders.location + 24, [line length] - clientRequestHeaders.location - 24)];
                end = [line rangeOfString:@" tend " options:NSCaseInsensitiveSearch range:NSMakeRange(start.location, [line length] - start.location)];
                clientHeadersString = [line substringWithRange:NSMakeRange(start.location, end.location - start.location)];
                clientHeaders = [clientHeadersString componentsSeparatedByString:@" hend "];
                
                clientMethodLine = clientHeaders[0];
                clientParams = [clientMethodLine componentsSeparatedByString:@" "];
                (*sentMessages)[@"url"] = clientParams[1];
                (*sentMessages)[@"version"] = clientParams[2];
                
                i = 1;
                len = [clientHeaders count];
                while (i < len)
                {
                    header = [clientHeaders[i] mutableCopy];
                    [header stripBlanks];
                    j = 0;
                    while (j < hlen)
                    {
                        name = requestHeaders[j];
                        if ([NSMutableArray nameOf:header is:name])
                        {
                            index = [NSString stringWithFormat:@"client%@", name];
                            nameLen = [name length];
                            value = [[header substringWithRange:NSMakeRange(nameLen + 1, [header length] - nameLen - 1)] mutableCopy];
                            [value stripBlanks];
                            (*sentMessages)[index] = value;
                            break;
                        }
                        ++j;
                    }
                    ++i;
                }
                
            }
            else if (serverRequestHeaders.location != NSNotFound)
            {
                (*receivedMessages)[@"server request headers"] =               @"has";
                hend = [line rangeOfString:@" tend"];
                serverHeadersString = [line substringWithRange:NSMakeRange(serverRequestHeaders.location + 29, hend.location - serverRequestHeaders.location - 29)];
                serverHeaders = [serverHeadersString componentsSeparatedByString:@" hend "];
                
                i = 0;
                len = [serverHeaders count];
                while (i < len)
                {
                    header = [serverHeaders[i] mutableCopy];
                    [header stripBlanks];
                    j = 0;
                    while (j < hlen)
                    {
                        name = requestHeaders[j];
                        if ([NSMutableArray nameOf:header is:name])
                        {
                            index = [NSString stringWithFormat:@"server%@", name];
                            nameLen = [name length];
                            tend = [header rangeOfString:@" tend "];
                            if (tend.location == NSNotFound)
                                value = [[header substringWithRange:NSMakeRange(nameLen + 1, [header length] - nameLen - 1)] mutableCopy];
                            else
                                value = [[header substringWithRange:NSMakeRange(nameLen + 1, tend.location - nameLen - 1)] mutableCopy];
                            [value stripBlanks];
                            (*receivedMessages)[index] = value;
                            break;
                        }
                        ++j;
                    }
                    ++i;
                }
            }
        }
        
        i = 0;
        for(item in types)
        {
            type = [line rangeOfString:item];
            if (type.location != NSNotFound)
            {
                if (client.location != NSNotFound)
                    (*sentMessages)[item] = @"has";
                if (server.location != NSNotFound)
                    (*receivedMessages)[item] = @"has";
            }
        }
    }
}

+ (void) optionsMessagesInLogFile:(UMLogFile *)dst sent:(NSMutableDictionary **)sentMessages received:(NSMutableDictionary **)receivedMessages messagesSent:(long *)numberOfSent messagesReceived:(long *)numberOfReceived
{
    NSArray *types, *clientHeaders, *serverHeaders;
    int ret;
    NSString *line;
    long i;
    NSRange client, test, server, options, type, request, reply, serverReplyHeaders, clientReplyHeaders, serverRequestHeaders, clientRequestHeaders, start, end, hend, allow, aend;
    NSString *item;
    NSString *clientHeadersString, *serverHeadersString;
    long size;
    NSString *clientMethodLine;
    NSArray *clientParams;
    NSMutableString *allowString;
    
    *sentMessages = [NSMutableDictionary dictionary];
    *receivedMessages = [NSMutableDictionary dictionary];
    *numberOfSent = 0;
    *numberOfReceived = 0;
    
    types = @[@"options content"];
    size = [dst updateFileSize];
    if (size == -1)
        return;
    
    ret = 1;
    while(ret == 1)
    {
        line = [dst readLine:&ret];
        if(ret != 1)
            continue;
        NSLog(@"%@", line);
        test = [line rangeOfString:@"Test HTTP"];
        options = [line rangeOfString:@"options" options:NSCaseInsensitiveSearch];
        clientReplyHeaders = [line rangeOfString:@"received options reply headers"  options:NSCaseInsensitiveSearch];
        serverReplyHeaders = [line rangeOfString:@"sent options reply headers"  options:NSCaseInsensitiveSearch];
        clientRequestHeaders = [line rangeOfString:@"sent options request headers"  options:NSCaseInsensitiveSearch];
        serverRequestHeaders = [line rangeOfString:@"received options request headers"  options:NSCaseInsensitiveSearch];
        request = [line rangeOfString:@"Started request"];
        reply = [line rangeOfString:@"Done with request"];
        
        if (test.location == NSNotFound)
            continue;
        
        if (request.location != NSNotFound)
        {
            (*sentMessages)[@"request done"] = @"has";
            ++*numberOfSent;
        }
        
        if (reply.location != NSNotFound)
        {
            (*receivedMessages)[@"reply received"] = @"has";
            ++*numberOfReceived;
        }
        
        if (options.location != NSNotFound)
        {
            if (clientReplyHeaders.location != NSNotFound)
            {
                long hitLen = [@"received options reply headers" length];
                (*sentMessages)[@"client reply headers"] = @"has";
                allow = [line rangeOfString:@" allow "  options:NSCaseInsensitiveSearch range:NSMakeRange(clientReplyHeaders.location + hitLen + 1, [line length] - clientReplyHeaders.location - hitLen - 1)];
                hitLen = [@" content type " length];
                aend = [line rangeOfString:@" content type " options:NSCaseInsensitiveSearch range:NSMakeRange(allow.location + hitLen + 1, [line length] - allow.location - hitLen - 1)];
                hitLen = [@" allow " length];
                allowString = [[line substringWithRange:NSMakeRange(allow.location + hitLen + 1, aend.location - allow.location - hitLen - 1)] mutableCopy];
                [allowString stripBlanks];
                (*sentMessages)[@"allow"] = allowString;
            }
            else if (serverReplyHeaders.location != NSNotFound)
            {
                long hitLen = [@"sent options reply headers" length];
                (*receivedMessages)[@"server reply headers"] = @"has";
                allow = [line rangeOfString:@" allow "  options:NSCaseInsensitiveSearch range:NSMakeRange(serverReplyHeaders.location + hitLen + 1, [line length] - serverReplyHeaders.location - hitLen - 1)];
                hitLen = [@" allow " length];
                aend = [line rangeOfString:@" and with content length " options:NSCaseInsensitiveSearch range:NSMakeRange(allow.location + hitLen + 1, [line length] - allow.location - hitLen - 1)];
                allowString = [[line substringWithRange:NSMakeRange(allow.location + 7, aend.location - allow.location - 7)] mutableCopy];
                [allowString stripBlanks];
                (*receivedMessages)[@"allow"] = allowString;
            }
            else if (clientRequestHeaders.location != NSNotFound)
            {
                long hitLen = [@"sent options request headers" length];
                (*sentMessages)[@"client request headers"] = @"has";
                start = [line rangeOfString:@"OPTIONS" options:NSCaseInsensitiveSearch range:NSMakeRange(clientRequestHeaders.location + hitLen + 1, [line length] - clientRequestHeaders.location - hitLen - 1)];
                end = [line rangeOfString:@" tend " options:NSCaseInsensitiveSearch range:NSMakeRange(start.location, [line length] - start.location)];
                clientHeadersString = [line substringWithRange:NSMakeRange(start.location, end.location - start.location)];
                clientHeaders = [clientHeadersString componentsSeparatedByString:@" hend "];
                
                clientMethodLine = clientHeaders[0];
                clientParams = [clientMethodLine componentsSeparatedByString:@" "];
                (*sentMessages)[@"url"] = clientParams[1];
                (*sentMessages)[@"version"] = clientParams[2];
            }
            else if (serverRequestHeaders.location != NSNotFound)
            {
                long hitLen = [@"received options request headers" length];
                (*receivedMessages)[@"server request headers"] = @"has";
                hend = [line rangeOfString:@" tend" options:NSCaseInsensitiveSearch range:NSMakeRange(serverRequestHeaders.location, [line length] - serverRequestHeaders.location)];
                serverHeadersString = [line substringWithRange:NSMakeRange(serverRequestHeaders.location + hitLen + 1, hend.location - serverRequestHeaders.location - hitLen - 1)];
                serverHeaders = [serverHeadersString componentsSeparatedByString:@" hend "];
            }
        }
        
        i = 0;
        for(item in types)
        {
            type = [line rangeOfString:item];
            if (type.location != NSNotFound)
            {
                if (client.location != NSNotFound)
                    (*sentMessages)[item] = @"has";
                if (server.location != NSNotFound)
                    (*receivedMessages)[item] = @"has";
            }
        }
    }
}

+ (void) traceMessagesInLogFile:(UMLogFile *)dst sent:(NSMutableDictionary **)sentMessages received:(NSMutableDictionary **)receivedMessages messagesSent:(long *)numberOfSent messagesReceived:(long *)numberOfReceived contentsSent:(long *)numberOfContentsSent contentsReceived:(long *)numberOfContentsReceived
{
    NSArray *types, *clientHeaders, *serverHeaders;
    int ret;
    NSString *line;
    long i;
    NSRange client, test, server, trace, type, request, reply, serverReplyHeaders, clientReplyHeaders, serverRequestHeaders, clientRequestHeaders, contentType, charset, contentLength, start, end, hend;
    NSString *item;
    NSRange space;
    NSString *contentTypeValue, *charsetValue, *contentLengthValue, *clientHeadersString, *serverHeadersString;
    NSMutableString *contentValue;
    long size;
    NSString *clientMethodLine;
    NSArray *clientParams;
    
    *sentMessages = [NSMutableDictionary dictionary];
    *receivedMessages = [NSMutableDictionary dictionary];
    *numberOfSent = 0;
    *numberOfReceived = 0;
    *numberOfContentsSent = 0;
    *numberOfContentsReceived = 0;
    
    types = @[@"trace content"];
    size = [dst updateFileSize];
    if (size == -1)
        return;
    
    ret = 1;
    while(ret == 1)
    {
        line = [dst readLine:&ret];
        if(ret != 1)
            continue;
        NSLog(@"%@", line);
        test = [line rangeOfString:@"Test HTTP"];
        trace = [line rangeOfString:@"trace" options:NSCaseInsensitiveSearch];
        client = [line rangeOfString:@"sent content"];
        server = [line rangeOfString:@"received trace content"];
        clientReplyHeaders = [line rangeOfString:@"received trace reply headers"  options:NSCaseInsensitiveSearch];
        serverReplyHeaders = [line rangeOfString:@"sent trace reply headers"  options:NSCaseInsensitiveSearch];
        clientRequestHeaders = [line rangeOfString:@"sent trace request headers"  options:NSCaseInsensitiveSearch];
        serverRequestHeaders = [line rangeOfString:@"received trace request headers"  options:NSCaseInsensitiveSearch];
        request = [line rangeOfString:@"Started request"];
        reply = [line rangeOfString:@"Done with request"];
        contentType = [line rangeOfString:@"content type"];
        charset = [line rangeOfString:@"charset"];
        contentLength = [line rangeOfString:@"content length"];
        
        if (test.location == NSNotFound)
            continue;
        
        if (request.location != NSNotFound)
        {
            (*sentMessages)[@"request done"] = @"has";
            ++*numberOfSent;
        }
        
        if (reply.location != NSNotFound)
        {
            (*receivedMessages)[@"reply received"] = @"has";
            ++*numberOfReceived;
        }
        
        if (trace.location != NSNotFound)
        {
            if (client.location != NSNotFound)
            {
                ++*numberOfContentsSent;
                (*sentMessages)[@"client trace"] = @"has";
                contentValue = [[line substringWithRange:NSMakeRange(client.location + 13, [line length] - client.location - 13)] mutableCopy];
                [contentValue stripBlanks];
                [contentValue replaceOccurrencesOfString:@"via trace" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [contentValue length])];
                [contentValue replaceOccurrencesOfString:@" bend  bend " withString:@"\r\n\r\n" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [contentValue length])];
                [contentValue replaceOccurrencesOfString:@" bend " withString:@"\r\n" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [contentValue length])];
                [contentValue replaceOccurrencesOfString:@" trend" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [contentValue length])];
                [contentValue stripSpaces];
                (*sentMessages)[@"content"] = contentValue;
            }
            else if (server.location != NSNotFound)
            {
                ++*numberOfContentsReceived;
                (*receivedMessages)[@"server trace"] = @"has";
                contentValue = [[line substringWithRange:NSMakeRange(server.location + 22, [line length] - server.location - 22)] mutableCopy];
                [contentValue stripBlanks];
                [contentValue replaceOccurrencesOfString:@" bend  bend " withString:@"\r\n\r\n" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [contentValue length])];
                [contentValue replaceOccurrencesOfString:@" bend " withString:@"\r\n" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [contentValue length])];
                [contentValue replaceOccurrencesOfString:@" trend" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [contentValue length])];
                [contentValue stripSpaces];
                (*receivedMessages)[@"content"] = contentValue;
            }
            else if (clientReplyHeaders.location != NSNotFound)
            {
                (*sentMessages)[@"client reply headers"] = @"has";
                if (contentType.location != NSNotFound)
                {
                    space = [line rangeOfString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(contentType.location + 13, [line length] - contentType.location - 13)];
                    if (space.location != NSNotFound)
                    {
                        contentTypeValue = [line substringWithRange:NSMakeRange(contentType.location + 13, space.location - contentType.location - 13)];
                        (*sentMessages)[@"content type"] = contentTypeValue;
                    }
                }
                if (charset.location != NSNotFound)
                {
                    space = [line rangeOfString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(charset.location + 8, [line length] - charset.location - 8)];
                    if (space.location != NSNotFound)
                    {
                        charsetValue = [line substringWithRange:NSMakeRange(charset.location + 8, space.location - charset.location - 8)];
                        (*sentMessages)[@"charset"] = charsetValue;
                    }
                }
                if (contentLength.location != NSNotFound)
                {
                    space = [line rangeOfString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(contentLength.location + 15, [line length] - contentLength.location - 15)];
                    if (space.location != NSNotFound)
                    {
                        contentLengthValue = [line substringWithRange:NSMakeRange(contentLength.location + 15, space.location - contentLength.location - 15)];
                        (*sentMessages)[@"content length"] = contentLengthValue;
                    }
                }
            }
            else if (serverReplyHeaders.location != NSNotFound)
            {
                (*receivedMessages)[@"server reply headers"] = @"has";
                if (contentType.location != NSNotFound)
                {
                    space = [line rangeOfString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(contentType.location + 13, [line length] - contentType.location - 13)];
                    if (space.location != NSNotFound)
                    {
                        contentTypeValue = [line substringWithRange:NSMakeRange(contentType.location + 13, space.location - contentType.location - 13)];
                        (*receivedMessages)[@"content type"] = contentTypeValue;
                    }
                }
                if (charset.location != NSNotFound)
                {
                    space = [line rangeOfString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(charset.location + 8, [line length] - charset.location - 8)];
                    if (space.location != NSNotFound)
                    {
                        charsetValue = [line substringWithRange:NSMakeRange(charset.location + 8, space.location - charset.location - 8)];
                        (*receivedMessages)[@"charset"] = charsetValue;
                    }
                }
                if (contentLength.location != NSNotFound)
                {
                    space = [line rangeOfString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(contentLength.location + 15, [line length] - contentLength.location - 15)];
                    if (space.location != NSNotFound)
                    {
                        contentLengthValue = [line substringWithRange:NSMakeRange(contentLength.location + 15, space.location - contentLength.location - 15)];
                        (*receivedMessages)[@"content length"] = contentLengthValue;
                    }
                }
            }
            else if (clientRequestHeaders.location != NSNotFound)
            {
                (*sentMessages)[@"client request headers"] = @"has";
                start = [line rangeOfString:@"TRACE" options:NSCaseInsensitiveSearch range:NSMakeRange(clientRequestHeaders.location + 24, [line length] - clientRequestHeaders.location - 24)];
                end = [line rangeOfString:@" tend " options:NSCaseInsensitiveSearch range:NSMakeRange(start.location, [line length] - start.location)];
                clientHeadersString = [line substringWithRange:NSMakeRange(start.location, end.location - start.location)];
                clientHeaders = [clientHeadersString componentsSeparatedByString:@" hend "];
                
                clientMethodLine = clientHeaders[0];
                clientParams = [clientMethodLine componentsSeparatedByString:@" "];
                (*sentMessages)[@"url"] = clientParams[1];
                (*sentMessages)[@"version"] = clientParams[2];
                
            }
            else if (serverRequestHeaders.location != NSNotFound)
            {
                (*receivedMessages)[@"server request headers"] = @"has";
                hend = [line rangeOfString:@" tend" options:NSCaseInsensitiveSearch range:NSMakeRange(serverRequestHeaders.location, [line length] - serverRequestHeaders.location)];
                serverHeadersString = [line substringWithRange:NSMakeRange(serverRequestHeaders.location + 29, hend.location - serverRequestHeaders.location - 29)];
                serverHeaders = [serverHeadersString componentsSeparatedByString:@" hend "];
            }
        }
        
        i = 0;
        for(item in types)
        {
            type = [line rangeOfString:item];
            if (type.location != NSNotFound)
            {
                if (client.location != NSNotFound)
                    (*sentMessages)[item] = @"has";
                if (server.location != NSNotFound)
                    (*receivedMessages)[item] = @"has";
            }
        }
    }
}

+ (void)configHTTPClientFromConfigFile:(NSString *)cfgName withUserName:(NSString **)username andPassword:(NSString **)password andLogFile:(NSString **)logFile andURLs:(NSMutableArray **)urls andText:(NSString **)text andHeaders:(NSMutableArray **)split andPostContent:(NSString **)content andCertKeyFile:(NSString **)certkey andNumberOfRequests:(long *)maxRequests  andServer:(NSString **)host andServerPort:(long *)port
{
    NSString *urlString;
    NSString *headerFile = nil;
    NSString *headersString = nil;
    NSError *error;
    NSString *contentFile;
    NSString *oldPath;
    
    UMConfig *cfg = [[UMConfig alloc] initWithFileName:cfgName];
    [cfg allowSingleGroup:@"core"];
    [cfg read]; 
    
    NSDictionary *grp = [cfg getSingleGroup:@"core"];
    if (!grp)
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"configuration file ulibTests/http-test.conf must have group core" userInfo:@{@"backtrace": UMBacktrace(NULL,0) }];
    }
    *username = grp[@"username"];
    *password = grp[@"password"];
    
    urlString = grp[@"urls"];
    *urls = [[urlString componentsSeparatedByString:@","] mutableCopy];
    
    *text = grp[@"msg-text"];
    
    headerFile = grp[@"header-file"];
    if (headerFile) 
    {
        oldPath   = [[NSFileManager defaultManager] currentDirectoryPath];
        headersString = [NSString stringWithContentsOfFile:headerFile encoding:NSASCIIStringEncoding error:&error];
    }
    *split = [[headersString componentsSeparatedByString:@"\n"] mutableCopy];
    NSMutableArray *discardedItems = [NSMutableArray array];
    NSString *item;
    
    for (item in *split)
    {
        if ([item isEqualToString:@""])
            [discardedItems addObject:item];
    }
    [*split removeObjectsInArray:discardedItems];
    
    contentFile = grp[@"content-file"];
    if (contentFile)
        *content = [NSString stringWithContentsOfFile:contentFile encoding:NSUTF8StringEncoding error:&error];
    else
        *content = nil;
    
    *certkey = grp[@"certkey-file"];
    *maxRequests = [grp[@"max-requests"] integerValue];
    
    *host = grp[@"host"];
    if(!(*host))
       @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"configuration file must have variable host" userInfo:nil];
    
    *port = [grp[@"port"] integerValue];
    if (*port == 0)
        *port = UMHTTP_DEFAULT_PORT;
    
    NSString *cfgName2 = @"ulibTests/http-server.conf";
    UMConfig *cfg2 = [[UMConfig alloc] initWithFileName:cfgName2];
    [cfg2 allowSingleGroup:@"core"];
    [cfg2 allowSingleGroup:@"auth"];
    [cfg2 read]; 
    
    NSDictionary *grp2 = [cfg2 getSingleGroup:@"core"];
    if (!grp2)
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"configuration file ulibTests/http-server.conf must have group core" userInfo:nil];
    
    *logFile = grp2[@"log-file"];
}

+ (void) putMessagesInLogFile:(UMLogFile *)dst sent:(NSMutableDictionary **)sentMessages received:(NSMutableDictionary **)receivedMessages messagesSent:(long *)numberOfSent messagesReceived:(long *)numberOfReceived contentsSent:(long *)numberOfContentsSent contentsReceived:(long *)numberOfContentsReceived;
{
    NSArray *types, *clientHeaders, *serverHeaders;
    int ret;
    NSString *line;
    long i, j;
    NSRange test, put, request, reply, serverReplyHeaders, clientReplyHeaders, serverRequestHeaders, clientRequestHeaders, start, end, clientRequestBody, serverRequestBody, bend, semicolon, type, client, server;
    NSString *clientString, *serverString, *clientBody, *serverBody, *clientHeadersString, *serverHeadersString;
    NSUInteger len;
    NSArray *requestData;
    long size;
    NSMutableString *header;
    long hlen, nameLen;
    NSArray *requestHeaders;
    NSString *name, *index;
    NSMutableString *value;
    NSMutableString *charset;
    NSString *item;
    
    requestHeaders = @[@"Accept", @"Accept-Encoding", @"Accept-Language", @"Authorization", @"Connection", @"Host", @"User-Agent", @"Content-Type", @"Content-Length"];
    
    *sentMessages = [NSMutableDictionary dictionary];
    *receivedMessages = [NSMutableDictionary dictionary];
    *numberOfSent = 0;
    *numberOfReceived = 0;
    *numberOfContentsSent = 0;
    *numberOfContentsReceived = 0;
    
    types = @[@"put content"];
    size = [dst updateFileSize];
    if (size == -1)
        return;
    
    ret = 1;
    while(ret == 1)
    {
        line = [dst readLine:&ret];
        if(ret != 1)
            continue;
        NSLog(@"%@", line);
        
        test = [line rangeOfString:@"Test HTTP"];
        put = [line rangeOfString:@"put" options:NSCaseInsensitiveSearch];
        clientReplyHeaders = [line rangeOfString:@"received put reply headers"  options:NSCaseInsensitiveSearch];
        serverReplyHeaders = [line rangeOfString:@"sent put reply headers"  options:NSCaseInsensitiveSearch];
        clientRequestHeaders = [line rangeOfString:@"sent put request headers"  options:NSCaseInsensitiveSearch];
        serverRequestHeaders = [line rangeOfString:@"received put request headers"  options:NSCaseInsensitiveSearch];
        clientRequestBody = [line rangeOfString:@"sent put request body"  options:NSCaseInsensitiveSearch];
        serverRequestBody = [line rangeOfString:@"received put request body"  options:NSCaseInsensitiveSearch];
        request = [line rangeOfString:@"Started request"];
        reply = [line rangeOfString:@"Done with request"];
        client = [line rangeOfString:@"sent content"];
        server = [line rangeOfString:@"received put content"];
        
        if (test.location == NSNotFound)
            continue;
        
        if (request.location != NSNotFound)
        {
            (*sentMessages)[@"request done"] = @"has";
            ++*numberOfSent;
        }
        
        if (reply.location != NSNotFound)
        {
            (*receivedMessages)[@"reply received"] = @"has";
            ++*numberOfReceived;
        }
        
        if (put.location != NSNotFound)
        {
            if (clientReplyHeaders.location != NSNotFound)
            {
                (*sentMessages)[@"client reply headers"] = @"has";
            }
            else if (serverReplyHeaders.location != NSNotFound)
            {
                (*receivedMessages)[@"server reply headers"] = @"has";
            }
            else if (clientRequestHeaders.location != NSNotFound)
            {
                long hitLen = [@"sent put request headers" length];
                (*sentMessages)[@"client request headers"] = @"has";
                start = [line rangeOfString:@"PUT" options:NSCaseInsensitiveSearch range:NSMakeRange(clientRequestHeaders.location + hitLen + 1, [line length] - clientRequestHeaders.location - hitLen - 1)];
                end = [line rangeOfString:@" tend " options:NSCaseInsensitiveSearch range:NSMakeRange(start.location, [line length] - start.location)];
                clientHeadersString = [line substringWithRange:NSMakeRange(start.location, end.location - start.location)];
                clientHeaders = [clientHeadersString componentsSeparatedByString:@" hend "];
                
                i = 0;
                len = [clientHeaders count];
                while (i < len)
                {
                    header = [clientHeaders[i] mutableCopy];
                    [header stripBlanks];
                    j = 0;
                    hlen = [requestHeaders count];
                    while (j < hlen)
                    {
                        name = requestHeaders[j];
                        if ([NSMutableArray nameOf:header is:name])
                        {
                            index = [NSString stringWithFormat:@"client%@", name];
                            nameLen = [name length];
                            value = [[header substringWithRange:NSMakeRange(nameLen + 1, [header length] - nameLen - 1)] mutableCopy];
                            [value stripBlanks];
                            (*sentMessages)[index] = value;
                            
                            if ([name compare:@"Content-Type"] == NSOrderedSame)
                            {
                                semicolon = [value rangeOfString:@";"];
                                charset = [[value substringFromIndex:semicolon.location + 10] mutableCopy];
                                [charset stripBlanks];
                                [charset stripQuotes];
                                (*sentMessages)[@"charset"] = charset;
                            }
                            
                            break;
                        }
                        ++j;
                    }
                    ++i;
                }
            }
            else if (serverRequestHeaders.location != NSNotFound)
            {
                long hitLen = [@"received put request headers" length];
                (*receivedMessages)[@"server request headers"] = @"has";
                end = [line rangeOfString:@" tend" options:NSCaseInsensitiveSearch range:NSMakeRange(serverRequestHeaders.location, [line length] - serverRequestHeaders.location)];
                serverHeadersString = [line substringWithRange:NSMakeRange(serverRequestHeaders.location + hitLen + 1, end.location - serverRequestHeaders.location - hitLen - 1)];
                serverHeaders = [serverHeadersString componentsSeparatedByString:@" hend "];
                
                i = 0;
                len = [serverHeaders count];
                while (i < len)
                {
                    header = [serverHeaders[i] mutableCopy];
                    [header stripBlanks];
                    j = 0;
                    hlen = [requestHeaders count];
                    while (j < hlen)
                    {
                        name = requestHeaders[j];
                        if ([NSMutableArray nameOf:header is:name])
                        {
                            index = [NSString stringWithFormat:@"server%@", name];
                            nameLen = [name length];
                            value = [[header substringWithRange:NSMakeRange(nameLen + 1, [header length] - nameLen - 1)] mutableCopy];
                            [value stripBlanks];
                            (*receivedMessages)[index] = value;
                            break;
                        }
                        ++j;
                    }
                    ++i;
                }
                
            }
            else if (clientRequestBody.location != NSNotFound)
            {
                long hitLen = [@"sent put request body" length];
                ++*numberOfContentsSent;
                (*sentMessages)[@"client request body"] = @"has";
                bend = [line rangeOfString:@" trend " options:NSCaseInsensitiveSearch range:NSMakeRange(clientRequestBody.location, [line length] - clientRequestBody.location)];
                clientString = [line substringWithRange:NSMakeRange(clientRequestBody.location + hitLen + 1, bend.location - clientRequestBody.location - hitLen - 1)];
                requestData = [clientString componentsSeparatedByString:@" bend "];
                   
                len = [requestData count];
                clientBody = requestData[len - 1];
                (*sentMessages)[@"clientbody"] = clientBody;
            }
            else if (serverRequestBody.location != NSNotFound)
            {
                long hitLen = [@"received put request body" length];
                ++*numberOfContentsReceived;
                (*receivedMessages)[@"server request body"] = @"has";
                bend = [line rangeOfString:@" trend " options:NSCaseInsensitiveSearch range:NSMakeRange(serverRequestBody.location, [line length] - serverRequestBody.location)];
                serverString = [line substringWithRange:NSMakeRange(serverRequestBody.location + hitLen + 1, bend.location - serverRequestBody.location - hitLen - 1)];
                requestData = [serverString componentsSeparatedByString:@" bend "];
                
                len = [requestData count];
                serverBody = requestData[len - 1];
                (*receivedMessages)[@"serverbody"] = serverBody;
            }
        }
        
        i = 0;
        for(item in types)
        {
            type = [line rangeOfString:item];
            if (type.location != NSNotFound)
            {
                if (client.location != NSNotFound)
                    (*sentMessages)[item] = @"has";
                if (server.location != NSNotFound)
                    (*receivedMessages)[item] = @"has";
            }
        }
    }
}

+ (void) deleteMessagesInLogFile:(UMLogFile *)dst sent:(NSMutableDictionary **)sentMessages received:(NSMutableDictionary **)receivedMessages messagesSent:(long *)numberOfSent messagesReceived:(long *)numberOfReceived
{
    long size;
    NSArray *types, *serverHeaders;
    int ret;
    NSString *line, *serverHeadersString;
    NSRange test, delete, request, reply, serverReplyHeaders, clientReplyHeaders, serverRequestHeaders, clientRequestHeaders, end, hend;
    
    *sentMessages = [NSMutableDictionary dictionary];
    *receivedMessages = [NSMutableDictionary dictionary];
    *numberOfSent = 0;
    *numberOfReceived = 0;
    
    types = @[@"delete content"];
    size = [dst updateFileSize];
    if (size == -1)
        return;
    
    ret = 1;
    while(ret == 1)
    {
        line = [dst readLine:&ret];
        if(ret != 1)
            continue;
        NSLog(@"%@", line);
        
        test = [line rangeOfString:@"Test HTTP"];
        delete = [line rangeOfString:@"delete" options:NSCaseInsensitiveSearch];
        clientReplyHeaders = [line rangeOfString:@"received delete reply headers"  options:NSCaseInsensitiveSearch];
        serverReplyHeaders = [line rangeOfString:@"sent delete reply headers"  options:NSCaseInsensitiveSearch];
        clientRequestHeaders = [line rangeOfString:@"sent delete request headers"  options:NSCaseInsensitiveSearch];
        serverRequestHeaders = [line rangeOfString:@"received delete request headers"  options:NSCaseInsensitiveSearch];
        request = [line rangeOfString:@"Started request"];
        reply = [line rangeOfString:@"Done with request"];
        
        if (test.location == NSNotFound)
            continue;
        
        if (request.location != NSNotFound)
        {
            (*sentMessages)[@"request done"] = @"has";
            ++*numberOfSent;
        }
        
        if (reply.location != NSNotFound)
        {
            (*receivedMessages)[@"reply received"] = @"has";
            ++*numberOfReceived;
        }
        
        if (delete.location != NSNotFound)
        {
            if (clientReplyHeaders.location != NSNotFound)
            {
                (*sentMessages)[@"client reply headers"] = @"has";
            }
            else if (serverReplyHeaders.location != NSNotFound)
            {
                (*receivedMessages)[@"server reply headers"] = @"has";
            }
            else if (clientRequestHeaders.location != NSNotFound)
            {
                (*sentMessages)[@"client request headers"] = @"has";
            }
            else if (serverRequestHeaders.location != NSNotFound)
            {
                long hitLen = [@"received delete request headers" length];
                (*receivedMessages)[@"server request headers"] = @"has";
                hend = [line rangeOfString:@"with url" options:NSCaseInsensitiveSearch range:NSMakeRange(serverRequestHeaders.location, [line length] - serverRequestHeaders.location)];
                end = [line rangeOfString:@" tend " options:NSCaseInsensitiveSearch range:NSMakeRange(serverRequestHeaders.location, [line length] - serverRequestHeaders.location)];
                serverHeadersString = [line substringWithRange:NSMakeRange(serverRequestHeaders.location + hitLen + 1, end.location - serverRequestHeaders.location - hitLen - 1)];
                serverHeaders = [serverHeadersString componentsSeparatedByString:@" hend "];
            }
        }
    }
}


+ (UMTestHTTPClient *) startRequestWithCaller:(UMHTTPCaller *)caller withId:(long)i withLogFile:(NSString *)logFile withURLs:(NSMutableArray *)urls withText:(NSString *)msgText withHeaders:(NSMutableArray *)split withPostContent:(NSString *)content withCertKeyFile:(NSString *)ck withHost:(NSString *)host withServerPort:(long)port withUsername:(NSString *)username withPassword:(NSString *)password andWithMethod:(UMHTTPMethod)method
{
    long *rid;
    NSMutableString *url;
    NSString *msg, *msg2;
    long numURLs = [urls count];
    UMTestHTTPClient *trans;
    NSString *methodString;
    
    rid = malloc(sizeof(long));
    *rid = i;
    
    url = urls[i % numURLs];
    if (msgText) 
    {
        [url appendString:@"&text="];
        [url appendString:msgText];
    }
    
    [caller addLogFile:logFile withSection:@"ulib tests" withSubsection:@"UMHTTPServer test" withName:@"Universal tests" ];
    trans = [[UMTestHTTPClient alloc] startRequestWithMethod:method 
                                                  withCaller:caller
                                                     withURL:url
                                                 withHeaders:split
                                                    withBody:content 
                                          followRedirections:0
                                                     withId:rid
                                            withCertificate:ck
                                                   withHost:host
                                                   withPort:port
                                              withUsername:username
                                              withPassword:password];
    
    if (trans)
    {
        methodString = [TestUMHTTPServer methodToString:method];
        NSString *u = [url stringByRemovingPercentEncoding];
        msg = [NSString stringWithFormat:@"Test HTTP: Started request with %@ number %ld with url: %@\r\n", [TestUMHTTPServer methodToString:method], *rid, u];
        [[caller logFeed] info:0 inSubsection:[caller subsection] withText:msg];
        msg2 = [NSString stringWithFormat:@"sent %@ request headers %@\r\n", methodString, split ? split : @"only headers Server and Close"];
        [[caller logFeed] debug:0 inSubsection:[caller subsection] withText:msg2];
    }
    
    return trans;
}

+ (int)receiveReply:(UMTestHTTPClient *)trans
{
    void *rid;
    int ret = 0;
    NSString *finalURL;
    NSMutableArray *replyh;
    NSString *replyb;
    NSMutableString *type = nil;
    NSMutableString *charset = nil;
    int status;
    NSString *msg, *msg1, *msg2, *msg3;
    UMHTTPCaller *caller;
    UMLogFeed *_logFeed;
    NSString *subsection;
    int method;
    NSString *contentLength;
    NSUInteger length;
    NSString *methodString;
    NSString *allow;
    NSMutableString *body;
        
    rid = [trans receiveResultReturningStatus:&status
                                           URL:&finalURL
                                       headers:&replyh
                                          body:&replyb
                                       doBlock:YES];
    if (!rid || ret == -1) 
        return -1;
    
    method = [trans method];
    
    caller = [trans caller];
    _logFeed = [caller logFeed];
    subsection = [caller subsection];
    _logFeed.copyToConsole = 1;
    
    msg2 = [NSString stringWithFormat:@"Test HTTP: Done with request with method %@, number %ld\r\n",  [TestUMHTTPServer methodToString:method], *(long *) rid];
    [_logFeed debug:0 inSubsection:subsection withText:msg2];
    free(rid);
    
    [replyh getContentType:&type andCharset:&charset];
    contentLength = [replyh findFirstWithName:@"Content-Length"];
    length = [contentLength integerValue];
    allow = [replyh findFirstWithName:@"Allow"];
    
    methodString =  [TestUMHTTPServer methodToString:method];
    msg = [NSString stringWithFormat:@"Test HTTP: received %@ reply headers: allow %@ content type %@ charset %@ and content length %d \r\n", methodString, (allow ? allow : @"none"), (type ? type : @"none"), (charset ? charset : @"none"),(int) length];
    [_logFeed debug:0 inSubsection:subsection withText:msg];
    
    msg1 = [NSString stringWithFormat:@"received %@ reply headers: %@\r\n", methodString, replyh ? replyh : @"none"];
    [_logFeed debug:0 inSubsection:subsection withText:msg1];
    
    if ([methodString compare:@"trace"] != NSOrderedSame)
        msg3 = [NSString stringWithFormat:@"Test HTTP: received %@ content %@\r\n", [methodString lowercaseString] ,replyb ? replyb : @"none"];
    else
    {
        body = [replyb mutableCopy];
        [body replaceOccurrencesOfString:@"\r\n" withString:@"\n" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [replyb length])];
        [body replaceOccurrencesOfString:@"\n" withString:@" bend " options:NSCaseInsensitiveSearch range:NSMakeRange(0, [body length])];
        [body appendString:@" trend "];
        msg3 = [NSString stringWithFormat:@"Test HTTP: received trace content %@\r\n", body ? body : @"none"];
    }
    [_logFeed debug:0 inSubsection:subsection withText:msg3];
    
    return 0;
}

- (void)clientThread:(UMHTTPCaller *)caller
{
    NSString *username;
    NSString *password;
    TestCounter *counter;
    long succeeded, failed;
    long in_queue;
    long i;
    NSString *logFile;
    NSMutableArray *urls;
    NSString *msgText;
    NSMutableArray *split;
    NSString *content;
    NSString *ck;
    long maxRequests = 0;
    NSString *host;
    long port = 0;
    UMTestHTTPClient *trans;
    NSString *configFile;
    
    @autoreleasepool
    {
        done = NO;
        succeeded = 0;
        failed = 0;
        counter = [[TestCounter alloc] init];
        in_queue = 0;
        
        configFile = @"ulibTests/http-test.conf";
        [TestUMHTTPServer configHTTPClientFromConfigFile:configFile
                                            withUserName:&username
                                             andPassword:&password
                                              andLogFile:&logFile
                                                 andURLs:&urls
                                                 andText:&msgText
                                              andHeaders:&split
                                          andPostContent:&content
                                          andCertKeyFile:&ck
                                     andNumberOfRequests:&maxRequests
                                               andServer:&host
                                           andServerPort:&port];
        if (username)
        {
            [split addBasicAuthWithUserName:username andPassword:password];
        }
        for (;;)
        {
            i = [counter increase];
            if (i >= maxRequests)
            {
                goto receiveRest;
            }
            trans = [TestUMHTTPServer startRequestWithCaller:caller
                                              withId:i 
                                         withLogFile:logFile 
                                            withURLs:urls 
                                            withText:msgText 
                                         withHeaders:split 
                                     withPostContent:nil
                                     withCertKeyFile:ck
                                            withHost:host
                                      withServerPort:port
                                        withUsername:username
                                         withPassword:password
                                        andWithMethod:[caller method]];

            ++in_queue;
            if ([TestUMHTTPServer receiveReply:trans] == -1)
            {
                ++failed;
            }
            else
            {
                ++succeeded;
            }
            --in_queue;
        }
        
receiveRest:
        while (in_queue > 0)
        {
            if ([TestUMHTTPServer receiveReply:trans] == -1)
            {
                ++failed;
            }
            else
            {
                ++succeeded;
            }
            --in_queue;
        }

        /* HTTP GET with content*/ 
        configFile = @"ulibTests/http-test-get-with-content.conf";
        [TestUMHTTPServer configHTTPClientFromConfigFile:configFile
                                            withUserName:&username
                                             andPassword:&password
                                              andLogFile:&logFile
                                                 andURLs:&urls
                                                 andText:&msgText
                                              andHeaders:&split
                                          andPostContent:&content
                                          andCertKeyFile:&ck
                                     andNumberOfRequests:&maxRequests
                                               andServer:&host
                                           andServerPort:&port];
        
        trans = [TestUMHTTPServer startRequestWithCaller:caller
                                                  withId:i 
                                             withLogFile:logFile 
                                                withURLs:urls 
                                                withText:msgText 
                                             withHeaders:split 
                                         withPostContent:content
                                         withCertKeyFile:ck
                                                withHost:host
                                          withServerPort:port
                                            withUsername:username
                                             withPassword:password
                                           andWithMethod:[caller method]];
        
        [TestUMHTTPServer receiveReply:trans];
        done = YES;
    }
}

- (void)clientPostThread:(UMHTTPCaller *)caller
{
    NSString *username;
    NSString *password;
    TestCounter *counter;
    long succeeded, failed;
    long in_queue;
    long i;
    NSString *logFile;
    NSMutableArray *urls;
    NSString *msgText;
    NSMutableArray *split;
    NSString *content;
    NSString *ck;
    long maxRequests = 0;
    NSString *host;
    long port = 0;
    UMTestHTTPClient *trans;
    NSString *configFile;
    
    @autoreleasepool
    {
        done = NO;
        succeeded = 0;
        failed = 0;
        counter = [[TestCounter alloc] init];
        in_queue = 0;
        
        configFile = @"ulibTests/http-post-test.conf";
        [TestUMHTTPServer configHTTPClientFromConfigFile:configFile
                                            withUserName:&username
                                             andPassword:&password
                                              andLogFile:&logFile
                                                 andURLs:&urls
                                                 andText:&msgText
                                              andHeaders:&split
                                          andPostContent:&content
                                          andCertKeyFile:&ck
                                     andNumberOfRequests:&maxRequests
                                               andServer:&host
                                           andServerPort:&port];
        
        
        for (;;)
        {
            i = [counter increase];
            if (i >= maxRequests)
                goto receiveRest;
            
            trans = [TestUMHTTPServer startRequestWithCaller:caller
                                                      withId:i 
                                                 withLogFile:logFile 
                                                    withURLs:urls 
                                                    withText:msgText 
                                                 withHeaders:split 
                                             withPostContent:content
                                             withCertKeyFile:ck
                                                    withHost:host
                                              withServerPort:port
                                                withUsername:username
                                                withPassword:password
                                               andWithMethod:[caller method]];
            
            ++in_queue;
            if ([TestUMHTTPServer receiveReply:trans] == -1)
                ++failed;
            else
                ++succeeded;
            --in_queue;
        }
        
receiveRest:
        while (in_queue > 0) {
            if ([TestUMHTTPServer receiveReply:trans] == -1)
                ++failed;
            else
                ++succeeded;
            --in_queue;
        }
        
        done = YES;

    }
}

- (void)clientHeadThread:(UMHTTPCaller *)caller
{
    NSString *username;
    NSString *password;
    TestCounter *counter;
    long succeeded, failed;
    long in_queue;
    long i;
    NSString *logFile;
    NSMutableArray *urls;
    NSString *msgText;
    NSMutableArray *split;
    NSString *content;
    NSString *ck;
    long maxRequests;
    NSString *host;
    long port;
    UMTestHTTPClient *trans;
    NSString *configFile;
    
    @autoreleasepool {
    
        done = NO;
        succeeded = 0;
        failed = 0;
        counter = [[TestCounter alloc] init];
        in_queue = 0;
        
        configFile = @"ulibTests/http-test.conf";
        [TestUMHTTPServer configHTTPClientFromConfigFile:configFile
                                            withUserName:&username
                                             andPassword:&password
                                              andLogFile:&logFile
                                                 andURLs:&urls
                                                 andText:&msgText
                                              andHeaders:&split
                                          andPostContent:&content
                                          andCertKeyFile:&ck
                                     andNumberOfRequests:&maxRequests
                                               andServer:&host
                                           andServerPort:&port];
        
        
        for (;;) {
            i = [counter increase];
            if (i >= maxRequests)
                goto receiveRest;
            
            trans = [TestUMHTTPServer startRequestWithCaller:caller
                                                      withId:i
                                                 withLogFile:logFile
                                                    withURLs:urls
                                                    withText:msgText
                                                 withHeaders:split
                                             withPostContent:content
                                             withCertKeyFile:ck
                                                    withHost:host
                                              withServerPort:port
                                                withUsername:username
                                                withPassword:password
                                               andWithMethod:[caller method]];
            
            ++in_queue;
            if ([TestUMHTTPServer receiveReply:trans] == -1)
                ++failed;
            else
                ++succeeded;
            --in_queue;
        }
        
receiveRest:
        while (in_queue > 0) {
            if ([TestUMHTTPServer receiveReply:trans] == -1)
                ++failed;
            else
                ++succeeded;
            --in_queue;
        }
        
        done = YES;
    
    }
}



@end
