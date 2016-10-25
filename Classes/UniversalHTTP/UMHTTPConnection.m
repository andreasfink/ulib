//
//  UMHTTPConnection.m
//  UniversalHTTP
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//


#import "UMHTTPConnection.h"
#import "UMHTTPServer.h"
#import "UMHTTPRequest.h"
#import "UMSocket.h"
#import "NSString+UMHTTP.h"
#import "NSMutableString+UMHTTP.h"
#import "NSMutableArray+UMHTTP.h"
#import "NSDictionary+UMHTTP.h"
#import "UMLogFeed.h"
#import "UMLock.h"

#include <poll.h>

@implementation UMHTTPConnection

@synthesize	server;
@synthesize	socket;
@synthesize	mustClose;
@synthesize	timeout;
@synthesize	lastActivity;
@synthesize currentRequest;

- (id)init
{
    return nil;
}

- (UMHTTPConnection *) initWithSocket:(UMSocket *)sk server:(UMHTTPServer *)s
{
    self = [super init];
	if(self)
	{
		server = s;
		socket = sk;
		lastActivity = nil;
		timeout = DEFAULT_HTTP_TIMEOUT;
	}
	return self;
}

- (NSString *)description
{
    NSMutableString *desc;
    
    desc = [[NSMutableString alloc] initWithString:@"UM HTTP Connection dump starts\n"];
    [desc appendFormat:@"socket used is %@\n", socket];
    [desc appendString:@"UM HTTP Connection dump ends\n"];
    return desc;
}

- (void) terminate
{
	[socket close];
}

- (void) connectionListener
{
	UMSocketError err;
    int receivePollTimeoutMs = 500;
    NSMutableData *appendToMe;

	lastActivity = [[NSDate alloc]init];
    cSection = UMHTTPConnectionRequestSectionFirstLine;

	mustClose = NO;
    if(socket.useSSL)
    {
        ulib_set_thread_name([NSString stringWithFormat:@"[UMHTTPConnection connectionListener] %@ (with SSL)",socket.description]);
        [socket startTLS];
    }
    else
    {
        ulib_set_thread_name([NSString stringWithFormat:@"[UMHTTPConnection connectionListener] %@",socket.description]);
    }
	while(mustClose == NO)
	{
        if (!socket)
        {
            NSLog(@"we have no socket");
            break;
        }
        
        UMSocketError pollResult = [socket dataIsAvailable:receivePollTimeoutMs];
        NSDate *now = [NSDate date];
        if (pollResult == UMSocketError_no_data)
        {
            NSTimeInterval idleTime = [now timeIntervalSinceDate:lastActivity];
            if(idleTime > 30)
            {
                mustClose = YES;
            }
            continue;
        }
        else if((pollResult == UMSocketError_has_data) ||
                (pollResult== UMSocketError_has_data_and_hup))
        {
            err = [socket receiveEverythingTo:&appendToMe];
            if(err != UMSocketError_no_error)
            {
                mustClose = YES;
            }
            if( [self checkForIncomingData:appendToMe] != 0)
            {
                mustClose = YES;
            }
            if(pollResult == UMSocketError_has_data_and_hup)
            {
                mustClose = YES;
            }
        }
        else
        {
            mustClose = YES;
        }
	}
	mustClose = YES;
	/* we're done with this thread so we must release our pool */
	/* tell the server process to terminate and release us */
	[server connectionDone:self];
}


/* returns error if it should exit */
- (int) checkForIncomingData:(NSMutableData *)appendToMe;
{
	const char *ptr = [appendToMe bytes];
	size_t n	= [appendToMe length];
	char *eol;
	
	if(cSection != UMHTTPConnectionRequestSectionData)
	{
		while((eol = memchr(ptr,'\n',n)))
		{
			NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
			NSString *line = [[NSString alloc]initWithBytes:ptr length:eol-ptr encoding:NSUTF8StringEncoding];
			size_t removeLen = eol-ptr+1;
			[appendToMe replaceBytesInRange:NSMakeRange(0,removeLen) withBytes:nil length:0];
			n -= removeLen;

			line = [line stringByTrimmingCharactersInSet:whitespace];
			if([line isEqual:@""])
			{
				cSection=UMHTTPConnectionRequestSectionData;
				break;
			}


			if(cSection==UMHTTPConnectionRequestSectionFirstLine)
			{
               NSArray *lineItems = [line componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
				if([lineItems count] != 3)
				{
					NSLog(@"HTTP protocol error. First line does not have 3 parts");
					cSection = UMHTTPConnectionRequestSectionErrorOrClose;
					return -1;
				}
				NSString *met = [[lineItems objectAtIndex:0]stringByTrimmingCharactersInSet:whitespace];
				NSString *path = [[lineItems objectAtIndex:1] stringByTrimmingCharactersInSet:whitespace];
				NSString *protocol = [[lineItems objectAtIndex:2] stringByTrimmingCharactersInSet:whitespace];
                self.currentRequest =[[UMHTTPRequest alloc]init];
				[currentRequest setMethod:met];
				[currentRequest setPath:path];
				[currentRequest setProtocolVersion:protocol];
                [currentRequest setConnection:self];
				cSection=UMHTTPConnectionRequestSectionHeaderLine;
				continue;
			}
			
            NSArray *lineItems = [line splitByFirstCharacter:':'];

//			NSArray *lineItems = [line componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@":"]];
			if([lineItems count] != 2)
			{
				NSLog(@"HTTP header line '%@' doesnt have exactly 2 items <header>:<value>",line);
				cSection = UMHTTPConnectionRequestSectionErrorOrClose;
				return -1;
			}

			NSString *header = [[lineItems objectAtIndex:0]stringByTrimmingCharactersInSet:whitespace];
			NSString *value = [[lineItems objectAtIndex:1] stringByTrimmingCharactersInSet:whitespace];
			[currentRequest setRequestHeader:header withValue:value];
			if([header isEqual:@"Content-Length"])
			{
				awaitingBytes = [value intValue];
			}
            else if ([header isEqual:@"Connection"])
            {
                [currentRequest setConnectionValue:value];
            }
            
			continue;
		}
	}
	if(cSection == UMHTTPConnectionRequestSectionData)
	{
		if(n >= awaitingBytes)
		{
			NSData *data = [[NSData alloc]initWithBytes:ptr length:n];
			[appendToMe replaceBytesInRange:NSMakeRange(0,n) withBytes:nil length:0];
			[currentRequest setRequestData:data];
            [self setLastActivity: [NSDate date]];
            [self processHTTPRequest:currentRequest];
            self.currentRequest = NULL; /* we are done with the request. this will let the object be released */
            
            if(mustClose == YES)
            {
                cSection = UMHTTPConnectionRequestSectionErrorOrClose;
            }
            else
            {
                cSection = UMHTTPConnectionRequestSectionFirstLine;
            }
            return 0;
		}
        else
        {

        }
	}
    return 0;
}	

- (void) processHTTPRequest:(UMHTTPRequest *)req
{
	NSString *protocolVersion = [req protocolVersion];
    NSString *connectionValue = [req connectionValue];
    NSString *method = [req method];
    NSData *resp;
#ifdef SENTEST
    NSString *contentType;
    NSString *contentLength;
    NSMutableArray *logHeaders;
#endif
    
	if([protocolVersion isEqual:@"HTTP/1.0"])
    {
		mustClose = YES;
    }
    
    if([connectionValue isEqual:@"close"])
    {
		mustClose = YES;
    }
    
    if (!protocolVersion || !(([protocolVersion isEqual:@"HTTP/1.1"]) || ([protocolVersion isEqual:@"HTTP/1.0"])))
	{
		[req setResponseCode:505];
		mustClose = YES;
        return;
    }
	
	if (!method)
	{
		[req setResponseCode:400];
		return;
	}
	else
	{
		if([method isEqual:@"GET"])
        {
			[server httpGet:req];
        }
		else if([method isEqual:@"POST"])
        {
			[server httpPost:req];
        }
		else if([method isEqual:@"HEAD"])
        {
			[server httpHead:req];
        }
		else if([method isEqual:@"PUT"])
        {
			[server httpPut:req];
        }
		else if([method isEqual:@"DELETE"])
        {
			[server httpDelete:req];
		}
        else if([method isEqual:@"TRACE"])
		{
            [server httpTrace:req];
        }
		else if([method isEqual:@"CONNECT"])
        {
			[server httpConnect:req];
        }
		else if([method isEqual:@"OPTIONS"])
        {
			[server httpOptions:req];
        }
		else
		{
			[req setResponseCode:HTTP_RESPONSE_CODE_BAD_REQUEST];
            [req setResponseHtmlString:[NSString stringWithFormat:@"Unknown method '%@'",method]];
			return;
		}
        if(req.awaitingCompletion == YES) /*async callback */
        {
            [req sleepUntilCompleted];
        }
        [req setResponseHeader:@"Server" withValue:[server serverName]];
        resp = [req extractResponse];
        [socket sendData:resp];
        
#ifdef SENTEST
        /* Sen test log parsing requires separator "\r\n". */
        NSString *subsection = @"sentest";
        NSString *msg = [NSString stringWithFormat:@"sent %@ reply headers %@\r\n", method, [req responseHeaders]];
        [logFeed debug:0 inSubsection:subsection withText:msg];
        
        logHeaders = [[req requestHeaders] toArray];
        contentType = [logHeaders findFirstWithName:@"Content-Type"];
        contentLength = [logHeaders findFirstWithName:@"Content-Length"];
        NSString *logItem = [[req requestHeaders] logDescription];
        NSString *url = [req path];
        NSString *msg1 = [NSString stringWithFormat:@"Test HTTP: received %@ request headers %@ with url %@ and version %@ and content type %@ and content length %@ fend \r\n", method ? method : @"GET", logItem, url ? url : @"not specified", protocolVersion ? protocolVersion : @"HTTP/1.1", contentType ? contentType : @"text/plain;charset=UTF-8", contentLength ? contentLength : @"0"];
        [logFeed debug:0 inSubsection:subsection withText:msg1];
#endif
	}
}



@end
