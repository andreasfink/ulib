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
    return [[NSstring alloc] initWithFormat:@"HTTP(%@)",socket];
}

- (void) terminate
{
	[socket close];
    server = NULL;
}


/* connectionListener reads a single HTTP requests from the socket and
   queues the processign for it
*/
- (void) connectionListener
{
	UMSocketError err;
    int receivePollTimeoutMs = 5000;
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
	while((self.mustClose == NO) && (self.inputClosed==NO))
	{
        if (!socket)
        {
            NSLog(@"UMHTTPConnection [%@]: we have no socket",self);
            break;
        }
        
        UMSocketError pollResult = [socket dataIsAvailable:receivePollTimeoutMs];
        NSDate *now = [NSDate new];
#ifdef HTTP_DEBUG
        NSLog(@"UMHTTPConnection [%@]: pollResult %d",self,pollResult);
#endif
        if (pollResult == UMSocketError_no_data)
        {
#ifdef HTTP_DEBUG
            NSLog(@"UMHTTPConnection [%@]: pollResult UMSocketError_no_data",self);
#endif

            if(lastActivity==NULL)
            {
                lastActivity = [NSDate new];
            }
            NSTimeInterval idleTime = [now timeIntervalSinceDate:lastActivity];
            if(idleTime > 30)
            {
#ifdef HTTP_DEBUG
                NSLog(@"UMHTTPConnection [%@]: timeout. mustClose set",self);
#endif
                self.mustClose = YES;
                break;
            }
            continue;
        }
        else if((pollResult == UMSocketError_has_data) ||
                (pollResult== UMSocketError_has_data_and_hup))
        {
#ifdef HTTP_DEBUG
            NSLog(@"UMHTTPConnection [%@]: data present",self);
#endif
            err = [socket receiveEverythingTo:&appendToMe];
            if(err != UMSocketError_no_error)
            {
#ifdef HTTP_DEBUG
                NSLog(@"UMHTTPConnection [%@]: receiveEverythingTo returns %d. mustClose set",self,err);
#endif
                self.mustClose = YES;
            }

            if( [self checkForIncomingData:appendToMe requestCompleted:&completeRequestReceived] != 0)
            {
#ifdef HTTP_DEBUG
                NSLog(@"UMHTTPConnection [%@]: checkForIncomingData  returns error. mustClose set. mustClose set",self);
#endif
                self.mustClose = YES;
            }
            else
            {
                if(pollResult == UMSocketError_has_data_and_hup)
                {
#ifdef HTTP_DEBUG
                    NSLog(@"UMHTTPConnection [%@]: hup received. inputClosed is set",self);
#endif
                    self.inputClosed = YES;
                }
                if(completeRequestReceived==NO)
                {
#ifdef HTTP_DEBUG
                    NSLog(@"UMHTTPConnection [%@]: completeRequestReceived=NO",self);
#endif
                    continue;
                }
                else
                {
                    /* if this is HTTP/1.1 with keepalive, this will initiate
                     another read request task once completed
                    otherwise mustClose will be set and we close it here */
#ifdef HTTP_DEBUG
                    NSLog(@"UMHTTPConnection [%@]: calling processHTTPRequest[currentRequest=%@]",self,currentRequest);
#endif
                    [self processHTTPRequest:currentRequest];
                    break;
                }
            }
        }
        else
        {
#ifdef HTTP_DEBUG
            NSLog(@"UMHTTPConnection [%@]: some error. mustClose set",self);
#endif

            self.mustClose = YES;
        }
    }
    if (self.mustClose)
    {
#ifdef HTTP_DEBUG
        NSLog(@"UMHTTPConnection [%@]: calling connectionDone",self);
#endif
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
                    NSLog(@"UMHTTPConnection [%@]: HTTP protocol error. First line does not have 3 parts",self);
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
                    NSLog(@"UMHTTPConnection [%@]: HTTP header line '%@' doesnt have exactly 2 items <header>:<value>",self,line);
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
            NSLog(@"UMHTTPConnection [%@]: if(@ >= awaitingBytes) = NO",self);
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
#ifdef HTTP_DEBUG
        NSLog(@"UMHTTPConnection [%@]: HTTP/1.0. mustClose set",self);
#endif

		self.mustClose = YES;
    }
    
    if([connectionValue isEqual:@"close"])
    {
#ifdef HTTP_DEBUG
        NSLog(@"UMHTTPConnection [%@]: Connection: close is set mustClose set",self);
#endif
		self.mustClose = YES;
    }
    
    if (!protocolVersion || !(([protocolVersion isEqual:@"HTTP/1.1"]) || ([protocolVersion isEqual:@"HTTP/1.0"])))
	{
		[req setResponseCode:505];
#ifdef HTTP_DEBUG
        NSLog(@"UMHTTPConnection [%@]: Connection: error 505. mustClose set",self);
#endif
		self.mustClose = YES;
        return;
    }
	
	if (!method)
	{
#ifdef HTTP_DEBUG
        NSLog(@"UMHTTPConnection [%@]: Connection: error 400. mustClose set",self);
#endif
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
#ifdef HTTP_DEBUG
                NSLog(@"UMHTTPConnection [%@]: error 400. unknown method",self);
#endif
                return;
            }
        }
        if(req.awaitingCompletion == YES) /*async callback */
        {
            req.connection = self;
            [server.pendingRequests addObject:req];
#ifdef HTTP_DEBUG
            NSLog(@"UMHTTPConnection [%@]: move to pending request (async)",self);
#endif
        }
        else
        {
            [req finishRequest];
        }
	}
}



@end
