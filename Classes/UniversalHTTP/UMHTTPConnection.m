//
//  UMHTTPConnection.m
//  UniversalHTTP
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
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
#import "UMHTTPTask_ProcessRequest.h"
#import "UMHTTPTask_ReadRequest.h"
#import "UMSynchronizedArray.h"
#import "UMThreadHelpers.h"
#import "UMTaskQueue.h"

#include <poll.h>

@implementation UMHTTPConnection

@synthesize	server;
@synthesize	socket;
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


/* this takes a socket and reads a HTTP header and readas a request */
/* returning NULL means socket closed and terminated */
/* returning an object means that object now owns the connection. Once it is processed it is in charge of
    writing the answer, closing the socket or calling startHttpConnection 
 again for reading the next request */

- (void) connectionListener
{
	UMSocketError err;
    int receivePollTimeoutMs = 500;
    NSMutableData *appendToMe;

	lastActivity = [[NSDate alloc]init];
    cSection = UMHTTPConnectionRequestSectionFirstLine;

	self.mustClose = NO;
    if(socket.useSSL)
    {
        ulib_set_thread_name([NSString stringWithFormat:@"[UMHTTPConnection connectionListener] %@ (with SSL)",socket.description]);
        if(socket.sslActive==NO)
        {
            [socket startTLS];
        }
    }
    else
    {
        ulib_set_thread_name([NSString stringWithFormat:@"[UMHTTPConnection connectionListener] %@",socket.description]);
    }
    BOOL completeRequestReceived = NO;
	while(self.mustClose == NO)
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
            if(lastActivity)
            {
                NSTimeInterval idleTime = [now timeIntervalSinceDate:lastActivity];
                if(idleTime > 30)
                {
                    self.mustClose = YES;
                }
            }
            else
            {
                lastActivity = [NSDate date];
            }
            continue;
        }
        else if((pollResult == UMSocketError_has_data) ||
                (pollResult== UMSocketError_has_data_and_hup))
        {
            err = [socket receiveEverythingTo:&appendToMe];
            if(err != UMSocketError_no_error)
            {
                self.mustClose = YES;
            }

            if( [self checkForIncomingData:appendToMe requestCompleted:&completeRequestReceived] != 0)
            {
                self.mustClose = YES;
            }
            else
            {
                if(pollResult == UMSocketError_has_data_and_hup)
                {
                    self.mustClose = YES;
                }
                else
                {
                    if(completeRequestReceived==NO)
                    {
                        continue;
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }
        else
        {
            self.mustClose = YES;
        }
	}
    if(completeRequestReceived)
    {
        UMHTTPTask_ProcessRequest *pr = [[UMHTTPTask_ProcessRequest alloc]initWithRequest:currentRequest connection:self];
        [server.taskQueue queueTask:pr];
    }
    if (self.mustClose)
    {
        /* we're done with this thread so we must release our pool */
        /* tell the server process to terminate and release us */
        [server connectionDone:self];
    }
}


/* returns error if it should exit */
- (int) checkForIncomingData:(NSMutableData *)appendToMe requestCompleted:(BOOL *)complete
{
	const char *ptr = [appendToMe bytes];
	size_t n	= [appendToMe length];
	char *eol;
    NSString *line = NULL;

	if(cSection != UMHTTPConnectionRequestSectionData)
	{
		while((eol = memchr(ptr,'\n',n)))
		{
			NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
			line = [[NSString alloc]initWithBytes:ptr length:eol-ptr encoding:NSUTF8StringEncoding];
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
                currentRequest =[[UMHTTPRequest alloc]init];
				currentRequest.method = met;
				currentRequest.path = path;
				currentRequest.protocolVersion = protocol;
                currentRequest.connection = self;
				cSection=UMHTTPConnectionRequestSectionHeaderLine;
				continue;
			}
			else
            {
                /* header lines */
                NSArray *lineItems = [line splitByFirstCharacter:':'];
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

            currentRequest.mustClose = self.mustClose;
            if(complete)
            {
                *complete = YES;
            }
            if(self.mustClose == YES)
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
            NSLog(@"if(@ >= awaitingBytes) = NO");
        }
	}
    return 0;
}	

- (void) processHTTPRequest:(UMHTTPRequest *)req
{
	NSString *protocolVersion = [req protocolVersion];
    NSString *connectionValue = [req connectionValue];
    NSString *method = [req method];
    
	if([protocolVersion isEqual:@"HTTP/1.0"])
    {
		self.mustClose = YES;
    }
    
    if([connectionValue isEqual:@"close"])
    {
		self.mustClose = YES;
    }
    
    if (!protocolVersion || !(([protocolVersion isEqual:@"HTTP/1.1"]) || ([protocolVersion isEqual:@"HTTP/1.0"])))
	{
		[req setResponseCode:505];
		self.mustClose = YES;
        return;
    }
	
	if (!method)
	{
		[req setResponseCode:400];
		return;
	}
	else
	{
        NSString *realm=@"realm";

        if([method isEqual:@"GET"])
        {
            [req extractGetParams];
        }

        if(req.authenticationStatus == UMHTTP_AUTHENTICATION_STATUS_UNTESTED)
        {
            req.authenticationStatus =  [server httpAuthenticateRequest:req realm:&realm];
        }

        if(req.authenticationStatus == UMHTTP_AUTHENTICATION_STATUS_FAILED)
        {
            [req setNotAuthorizedForRealm:realm];
            [req setResponseCode:HTTP_RESPONSE_CODE_UNAUTHORIZED];
            [req setResponseHtmlString:@"Authentication failed"];
            req.awaitingCompletion = NO;
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
        }
        if(req.awaitingCompletion == YES) /*async callback */
        {
            req.connection = self;
            [server.pendingRequests addObject:req];
        }
        else
        {
            [req finishRequest];
        }
	}
}



@end
