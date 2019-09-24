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


- (id)init
{
    return nil;
}

- (UMHTTPConnection *) initWithSocket:(UMSocket *)sk server:(UMHTTPServer *)s
{
    self = [super init];
	if(self)
	{
		_server = s;
		_socket = sk;
		_lastActivity = nil;
		_timeout = DEFAULT_HTTP_TIMEOUT;
	}
	return self;
}

- (NSString *)description
{
    if(_name)
    {
        return _name;
    }
    return [[NSString alloc] initWithFormat:@"HTTP(%@)",_socket];
}

/* UMHTTPServer calls us back to terminate */
- (void) terminateForServer
{
	[_socket close];
    _socket = NULL;
    _server = NULL;
}


/* connectionListener reads a single HTTP requests from the socket and
   queues the processign for it
*/
- (void) connectionListener
{
    NSAssert(_server!=NULL,@"server is null");
    
	UMSocketError err;
    int receivePollTimeoutMs = 5000;
    NSMutableData *appendToMe;

	_lastActivity = [[NSDate alloc]init];
    cSection = UMHTTPConnectionRequestSectionFirstLine;

	self.mustClose = NO;
    if(_socket.useSSL)
    {
        ulib_set_thread_name([NSString stringWithFormat:@"[UMHTTPConnection connectionListener] %@ (with SSL)",_socket.description]);
        if(_socket.sslActive==NO)
        {
            [_socket startTLS];
        }
    }
    else
    {
        ulib_set_thread_name([NSString stringWithFormat:@"[UMHTTPConnection connectionListener] %@",_socket.description]);
    }
    BOOL completeRequestReceived = NO;
	while((self.mustClose == NO) && (self.inputClosed==NO))
	{
        if (!_socket)
        {
            NSLog(@"[%@]: we have no socket",self.name);
            break;
        }
        UMSocketError pollResult = [_socket dataIsAvailable:receivePollTimeoutMs];
        NSDate *now = [NSDate new];
#ifdef HTTP_DEBUG
        NSLog(@"[%@]: pollResult %d",self.name,pollResult);
#endif
        if(pollResult == UMSocketError_invalid_file_descriptor)
        {
            self.inputClosed = YES;
        }
        else  if (pollResult == UMSocketError_no_data)
        {
#ifdef HTTP_DEBUG
            NSLog(@"[%@]: pollResult UMSocketError_no_data",self.name);
#endif

            if(_lastActivity==NULL)
            {
                _lastActivity = [NSDate new];
            }
            NSTimeInterval idleTime = [now timeIntervalSinceDate:_lastActivity];
            if(idleTime > 30)
            {
#ifdef HTTP_DEBUG
                NSLog(@"[%@]: timeout. mustClose set",self.name);
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
            NSLog(@"[%@]: data present",self.name);
#endif
            NSData *incomingData = NULL;
            err = [_socket receiveEverythingTo:&incomingData];
            if(incomingData.length>0)
            {
                if( appendToMe== NULL)
                {
                    appendToMe = [incomingData mutableCopy];
                }
                else
                {
                    [appendToMe appendData:incomingData];
                }
            }
            if(err != UMSocketError_no_error)
            {
#ifdef HTTP_DEBUG
                NSLog(@"[%@]: receiveEverythingTo returns %d. mustClose set",self.name,err);
#endif
                self.mustClose = YES;
            }

            if( [self checkForIncomingData:appendToMe requestCompleted:&completeRequestReceived] != 0)
            {
#ifdef HTTP_DEBUG
                NSLog(@"[%@]: checkForIncomingData  returns error. mustClose set. mustClose set",self.name);
#endif
                self.mustClose = YES;
            }
            else
            {
                if(pollResult == UMSocketError_has_data_and_hup)
                {
#ifdef HTTP_DEBUG
                    NSLog(@"[%@]: hup received. inputClosed is set",self.name);
#endif
                    self.inputClosed = YES;
                }
                if(completeRequestReceived==NO)
                {
#ifdef HTTP_DEBUG
                    NSLog(@"[%@]: completeRequestReceived=NO",self.name);
#endif
                    continue;
                }
                else
                {
                    /* if this is HTTP/1.1 with keepalive, this will initiate
                     another read request task once completed
                    otherwise mustClose will be set and we close it here */
#ifdef HTTP_DEBUG
                    NSLog(@"[%@]: calling processHTTPRequest[_currentRequest=%@]",self.name,_currentRequest.name);
#endif
                    [self processHTTPRequest:_currentRequest];
                    break;
                }
            }
        }
        else
        {
#ifdef HTTP_DEBUG
            NSLog(@"[%@]: some error. mustClose set",self.name);
#endif

            self.mustClose = YES;
        }
    }
    if ((self.mustClose) || (self.inputClosed) || (_socket == NULL))
    {
#ifdef HTTP_DEBUG
        NSLog(@"UMHTTPConnection [%@]: calling connectionDone",self);
#endif
        /* we're done with this thread so we must release our pool */
        /* tell the server process to terminate and release us */
        [_server connectionDone:self];
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
			NSCharacterSet *whitespace = [UMObject whitespaceAndNewlineCharacterSet];
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


                _currentRequest =[[UMHTTPRequest alloc]init];
				_currentRequest.method = met;
				_currentRequest.path = path;
				_currentRequest.protocolVersion = protocol;
                _currentRequest.connection = self;
				cSection=UMHTTPConnectionRequestSectionHeaderLine;
				continue;
			}
			else
            {
                /* header lines */
                NSArray *lineItems = [line splitByFirstCharacter:':'];
                if([lineItems count] != 2)
                {
                    NSLog(@"[%@]: HTTP header line '%@' doesnt have exactly 2 items <header>:<value>",self.name,line);
                    cSection = UMHTTPConnectionRequestSectionErrorOrClose;
                    return -1;
                }

                NSString *header = [[lineItems objectAtIndex:0]stringByTrimmingCharactersInSet:whitespace];
                NSString *value = [[lineItems objectAtIndex:1] stringByTrimmingCharactersInSet:whitespace];
                [_currentRequest setRequestHeader:header withValue:value];
                if([header isEqual:@"Content-Length"])
                {
                    _awaitingBytes = [value intValue];
                }
                else if ([header isEqual:@"Connection"])
                {
                    [_currentRequest setConnectionValue:value];
                }
            }
			continue;
		}
	}
	if(cSection == UMHTTPConnectionRequestSectionData)
	{
		if(n >= _awaitingBytes)
		{
			NSData *data = [[NSData alloc]initWithBytes:ptr length:n];
			[appendToMe replaceBytesInRange:NSMakeRange(0,n) withBytes:nil length:0];
			[_currentRequest setRequestData:data];
            self.lastActivity = [NSDate date];

            _currentRequest.mustClose = self.mustClose;
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
            NSLog(@"[%@]: if(@ >= awaitingBytes) = NO",self.name);
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
        NSLog(@"[%@]: HTTP/1.0. mustClose set",self.name);
#endif

		self.mustClose = YES;
    }
    if(_enableKeepalive==NO)
    {
#ifdef HTTP_DEBUG
        NSLog(@"[%@]: keepalive not enabled. mustClose set",self.name);
#endif
        self.mustClose = YES;
    }

    if([connectionValue isEqual:@"close"])
    {
#ifdef HTTP_DEBUG
        NSLog(@"[%@]: Connection: close is set mustClose set",self.name);
#endif
		self.mustClose = YES;
    }
    
    if (!protocolVersion || !(([protocolVersion isEqual:@"HTTP/1.1"]) || ([protocolVersion isEqual:@"HTTP/1.0"])))
	{
		[req setResponseCode:HTTP_RESPONSE_CODE_HTTP_VERSION_NOT_SUPPORTED];
#ifdef HTTP_DEBUG
        NSLog(@"[%@] Error 505 (Protocol Version not supported). mustClose set",self.name);
#endif
		self.mustClose = YES;
        return;
    }
	
	if (!method)
	{
#ifdef HTTP_DEBUG
        NSLog(@"[%@]: Error 400 (BadRequest). mustClose set",self.name);
#endif
		[req setResponseCode:HTTP_RESPONSE_CODE_BAD_REQUEST];
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
            req.authenticationStatus =  [_server httpAuthenticateRequest:req realm:&realm];
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
                [_server httpGet:req];
            }
            else if([method isEqual:@"POST"])
            {
                [_server httpPost:req];
            }
            else if([method isEqual:@"HEAD"])
            {
                [_server httpHead:req];
            }
            else if([method isEqual:@"PUT"])
            {
                [_server httpPut:req];
            }
            else if([method isEqual:@"DELETE"])
            {
                [_server httpDelete:req];
            }
            else if([method isEqual:@"TRACE"])
            {
                [_server httpTrace:req];
            }
            else if([method isEqual:@"CONNECT"])
            {
                [_server httpConnect:req];
            }
            else if([method isEqual:@"OPTIONS"])
            {
                [_server httpOptions:req];
            }
            else
            {
                [req setResponseCode:HTTP_RESPONSE_CODE_BAD_REQUEST];
                [req setResponseHtmlString:[NSString stringWithFormat:@"Unknown method '%@'",method]];
#ifdef HTTP_DEBUG
                NSLog(@"[%@]: error 400. unknown method",self.name);
#endif
                return;
            }
        }
        if(req.awaitingCompletion == YES) /*async callback */
        {
            req.connection = self;
            [_server.pendingRequests addObject:req];
#ifdef HTTP_DEBUG
            NSLog(@"[%@]: move to pending request (async)",self.name);
#endif
        }
        else
        {
            [req finishRequest];
        }
	}
}



@end
