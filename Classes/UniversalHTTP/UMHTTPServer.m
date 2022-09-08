//
//  UMHTTPServer.m
//  UniversalHTTP
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMHTTPServer.h"
#import "UMHTTPConnection.h"
#import "UMHTTPPageHandler.h"
#import "UMSocket.h"
#import "UMSleeper.h"
#import "UMLogFeed.h"
#import "UMHTTPRequest.h"
#include <sys/types.h>
#include <netinet/in.h>
#include <unistd.h>

#ifdef SENTEST
#import "UMConfig.h"
#endif
#import "UMTaskQueue.h"
#import "UMHTTPTask_ReadRequest.h"
#import "UMSynchronizedArray.h"
#import "UMThreadHelpers.h"

#define NSLOCK_LOCK(l)     [l lock];
#define NSLOCK_UNLOCK(l)   [l unlock];

@implementation UMHTTPServer

- (id) init
{
	return [self initWithPort:UMHTTP_DEFAULT_PORT socketType:UMSOCKET_TYPE_TCP];
}

- (id) initWithPort:(in_port_t)port 
{
	return [self initWithPort:port socketType:UMSOCKET_TYPE_TCP];
}

- (id) initWithPort:(in_port_t)port
         socketType:(UMSocketType)type
{
    return [self initWithPort:port socketType:type ssl:NO sslKeyFile:NULL sslCertFile:NULL];
}

- (id) initWithPort:(in_port_t)port
         socketType:(UMSocketType)type ssl:(BOOL)doSSL sslKeyFile:(NSString *)sslKeyFile sslCertFile:(NSString *)sslCertFile
{
    return [self initWithPort:port socketType:type ssl:doSSL sslKeyFile:sslKeyFile sslCertFile:sslCertFile  taskQueue:NULL];
}

- (id) initWithPort:(in_port_t)port socketType:(UMSocketType)type ssl:(BOOL)doSSL sslKeyFile:(NSString *)sslKeyFile sslCertFile:(NSString *)sslCertFile taskQueue:(UMTaskQueue *)tq
{
    self = [super init];
    if(self)
    {
        _processingThreadCount = ulib_cpu_count();
        if(_processingThreadCount > 8)
        {
            _processingThreadCount = 8;
        }

        _getPostDict = [[NSMutableDictionary alloc]init];
        _httpOperationsQueue = [NSOperationQueue mainQueue]; // [[NSOperationQueue alloc] init];
        _listenerSocket = [[UMSocket alloc] initWithType:type name:@"listener"];
        [_listenerSocket setLocalPort:port];
        _sleeper		= [[UMSleeper alloc]initFromFile:__FILE__ line:__LINE__ function:__func__];
        [_sleeper prepare];
        _connections = [[UMSynchronizedArray alloc] init];
        _terminatedConnections = [[UMSynchronizedArray alloc]init];
        _lock		= [[NSLock alloc] init];
        _sslLock     = [[NSLock alloc]init];
        _name =  @"unnamed";
        _receivePollTimeoutMs = 5000;
        _serverName = @"UMHTTPServer 1.0";
        _enableSSL = doSSL;

        if(tq)
        {
            _taskQueue = tq;
        }
        else
        {
            NSString *tqname;
            if(doSSL)
            {
                tqname = @"HTTPS_TaskQueue";
            }
            else
            {
                tqname = @"HTTP_TaskQueue";
            }
            _taskQueue = [[UMTaskQueue alloc]initWithNumberOfThreads:_processingThreadCount
                                                                name:tqname
                                                       enableLogging:NO];
            [_taskQueue start];
        }
        if(doSSL)
        {
            if(sslKeyFile)
            {
                [self setPrivateKeyFile:sslKeyFile];
            }
            if(sslCertFile)
            {
                [self setCertificateFile:sslCertFile];
            }
        }
        _pendingRequests = [[UMSynchronizedArray alloc]init];
    }
    return self;
}

- (NSString *)description
{
    NSMutableString *desc;
    
    desc = [[NSMutableString alloc] initWithString:@"UM HTTP server dump starts\n"];
    [desc appendFormat:@"server name was %@\n", _serverName ? _serverName : @"not set"];
    [desc appendFormat:@"listenerSocket was %@\n", _listenerSocket ? _listenerSocket : @"not set"];
    [desc appendFormat:@"connections were %@\n", _connections ? _connections : @"none"];
    [desc appendFormat:@"terminated connections were %@\n", _terminatedConnections ? _terminatedConnections : @"none"];
    [desc appendString:@"UM HTTP server dump ends\n"];
    return desc;
}

- (UMSocketError) start
{
	UMSocketError	sErr;
    self.logFeed.copyToConsole = 1;

    _listenerSocket.objectStatisticsName = [NSString stringWithFormat: @"UMSocket(UMHTTPServer-listener:%@)",_serverName];

    @autoreleasepool
    {
		if(self.status != UMHTTPServerStatus_notRunning)
		{
			[self.logFeed majorError:0 withText:[NSString stringWithFormat:@"HTTPServer '%@' on port %d failed to start because its already started",_name, [_listenerSocket requestedLocalPort]]];
			return UMSocketError_generic_error;
		}

		[self.logFeed info:0 withText:[NSString stringWithFormat:@"HTTPServer '%@' on port %d is starting up\r\n",_name, [_listenerSocket requestedLocalPort]]];

        NSLOCK_LOCK(_lock);

		self.status = UMHTTPServerStatus_startingUp;
        [self runSelectorInBackground:@selector(mainListener)
                           withObject:NULL
                                 file:__FILE__
                                 line:__LINE__
                             function:__func__];

 //       [NSThread detachNewThreadSelector:@selector(mainListener) toTarget:self withObject:nil];

		[_sleeper reset];

		while(self.status == UMHTTPServerStatus_startingUp)
        {
            UMSleeper_Signal sig =  [_sleeper sleep:100000];/* wait 100ms */
            if (sig == UMSleeper_Error)
            {
                break;
            }
        }

	    if( self.status == UMHTTPServerStatus_running )
	    {
		    sErr = UMSocketError_no_error;
	    }
	    else
	    {
		    sErr = _lastErr;
		    self.status = UMHTTPServerStatus_notRunning;
	    }
        NSLOCK_UNLOCK(_lock);
    
	    if( self.status == UMHTTPServerStatus_running)
	    {
            [self.logFeed info:0 withText:[NSString stringWithFormat:@"HTTPServer '%@' on port %d is running\n",_name, [_listenerSocket requestedLocalPort]]];
	    }
	    else
	    {
		    [self.logFeed majorError:0 withText:[NSString stringWithFormat:@"HTTPServer '%@' on port %d failed to start due to '%@'\n",_name, [_listenerSocket requestedLocalPort] ,[UMSocket getSocketErrorString:sErr]]];
	    }
    }
	return sErr;
}

- (void) mainListener
{
	@autoreleasepool
    {
        ulib_set_thread_name(@"[UMHTTPServer mainListener]");

        /* performSelector will handle pool by itself */
		UMSocketError sErr = 0;
        UMSocketError pollResult;


        /*

         if an application is restarted, the port might come back with
         address is already in use as the kernel has not yet deallocated it
         from the old process. if thats the case, we will retry
         every second up to a minute

        */

        _listenerRunning = YES;
        int counter = 0;
        while(counter < 60)
        {
            sErr  = [_listenerSocket bind];
            if(sErr != UMSocketError_address_already_in_use)
            {
                break;
            }
            usleep(1000000);
            counter += 1;
        }
		if(!sErr)
        {
			sErr  = [_listenerSocket listen];
        }
		if(sErr == UMSocketError_no_error)
        {
			self.status = UMHTTPServerStatus_running;
        }
		else
		{
			_lastErr = sErr;
			self.status = UMHTTPServerStatus_failed;
		}
        
        if([_advertizeName length]>0)
        {
            _listenerSocket.advertizeDomain=@"";
            _listenerSocket.advertizeName=_advertizeName;
            _listenerSocket.advertizeType=@"_http._tcp";
            [_listenerSocket publish];
        }
		[_sleeper wakeUp];
		
		while(self.status == UMHTTPServerStatus_running)
		{
            @autoreleasepool
            {
                //NSLog(@"_receivePollTimeoutMs=%ld",_receivePollTimeoutMs);
                pollResult = [_listenerSocket dataIsAvailable:_receivePollTimeoutMs];
                if(pollResult == UMSocketError_has_data_and_hup)
                {
                    NSLog(@"  UMSocketError_has_data_and_hup");

                    /* we get HTTP request but nobody is there to read the answer so we ignore it */
                    ;
                }
                else if (pollResult == UMSocketError_has_data)
                {
                    /* we get new HTTP request */
                    UMSocketError ret1=UMSocketError_no_error;
                    UMSocket *clientSocket = [_listenerSocket accept:&ret1];
                    if(clientSocket)
                    {
                        clientSocket.useSSL =_enableSSL;
                        clientSocket.serverSideKeyFilename  = _privateKeyFile;
                        clientSocket.serverSideKeyData      = _privateKeyFileData;
                        clientSocket.serverSideCertFilename = _certFile;
                        clientSocket.serverSideCertData     = _certFileData;
                        if ([self authorizeConnection:clientSocket] == UMHTTPServerAuthorize_successful)
                        {
                            UMHTTPConnection *con = [[UMHTTPConnection alloc] initWithSocket:clientSocket server:self];
                            con.name = [NSString stringWithFormat:@"HTTPConnection %@:%d",clientSocket.connectedRemoteAddress,clientSocket.connectedRemotePort];
                            con.enableKeepalive = _enableKeepalive;
                            con.server = self;
                            [_connections addObject:con];
                            //if(0)
                            //{
                            //    [con runSelectorInBackground:@selector(connectionListener)];
                            //}
                            //else
                            //{
                                UMHTTPTask_ReadRequest *task = [[UMHTTPTask_ReadRequest alloc]initWithConnection:con];
                                [_taskQueue queueTask:task];
                            //}
                            con = nil;
                        }
					    else
					    {
						    [clientSocket close];
					    }
                    }
                    else
                    {
                        _lastErr = ret1;
                    }
                }
                else if(pollResult == UMSocketError_no_data)
                {
                    usleep(10000); /* just to avoid too busy loops */
                }
                else
                {
                    _lastErr = pollResult;
                    self.status = UMHTTPServerStatus_failed;
                }
            }
            /* maintenance work */
			while ([_terminatedConnections count] > 0)
			{
                UMHTTPConnection *con = [_terminatedConnections removeFirst];
                if(con==NULL)
                {
                    break;
                }
                [con terminateForServer];
                con = NULL;
			}
		}
        self.status = UMHTTPServerStatus_shutDown;
        [_listenerSocket unpublish];
		[_listenerSocket close];
		_listenerRunning = NO;
    }
}

-(UMHTTPServerAuthorizeResult) authorizeConnection:(UMSocket *)us
{
	if(_authorizeConnectionDelegate)
    {
		if([_authorizeConnectionDelegate respondsToSelector:@selector(httpAuthorizeConnection:)])
        {
			return [_authorizeConnectionDelegate httpAuthorizeConnection:us];
        }
    }
	return UMHTTPServerAuthorize_successful;
}

- (void) stop
{
	[self.logFeed info:0 withText:[NSString stringWithFormat:@"HTTPServer '%@' on port %d is stopping\r\n",_name, [_listenerSocket requestedLocalPort]]];
    
    if((self.status !=UMHTTPServerStatus_running) && (_listenerRunning!=YES))
    {
		return;
    }
	self.status = UMHTTPServerStatus_shuttingDown;
	while(self.status == UMHTTPServerStatus_shuttingDown)
	{
        UMSleeper_Signal sig =  [_sleeper sleep:100000];/* wait 100ms */
        if (sig == UMSleeper_Error)
        {
            break;
        }
	}
	self.status = UMHTTPServerStatus_notRunning;
    
    [self.logFeed info:0 withText:[NSString stringWithFormat:@"HTTPServer '%@' on port %d is stopped\r\n",_name, [_listenerSocket requestedLocalPort]]];
}


- (void)connectionDone:(UMHTTPConnection *)con
{
    if(con)
    {
        [_connections removeObject:con];
        [_terminatedConnections addObject:con];
    }
}

/* calling the delegates */

- (void) httpOptions:(UMHTTPRequest *)req
{
	if( [_httpOptionsDelegate respondsToSelector:@selector(httpOptions:)] )
    {
		[_httpOptionsDelegate httpOptions:req];
    }
	else
    {
		[self httpUnknownMethod:req];
    }
}

- (void) httpGet:(UMHTTPRequest *)req
{
    [req extractGetParams];
    
	if( [_httpGetDelegate respondsToSelector:@selector(httpGet:)] )
    {
		[_httpGetDelegate  httpGet:req];
    }
	else
    {
		[self httpGetPost:req];
    }
}

- (void) httpHead:(UMHTTPRequest *)req
{
    [req extractGetParams];
	if( [_httpHeadDelegate respondsToSelector:@selector(httpHead:)] )
    {
		[_httpHeadDelegate  httpHead:req];
    }
	else
    {
		[self httpUnknownMethod:req];
    }
}

- (void) httpPost:(UMHTTPRequest *)req
{
    [req extractPostParams];

	if( [_httpPostDelegate respondsToSelector:@selector(httpPost:)] )
    {
		[_httpPostDelegate  httpPost:req];
    }
	else
    {
        [self httpGetPost:req];
    }
}

- (void) httpPut:(UMHTTPRequest *)req
{
    [req extractPutParams];

	if( [_httpPutDelegate respondsToSelector:@selector(httpPut:)] )
    {
		[_httpPutDelegate  httpPut:req];
    }
	else
    {
		[self httpGetPost:req];
    }
}


- (void) httpDelete:(UMHTTPRequest *)req
{
	if( [_httpDeleteDelegate respondsToSelector:@selector(httpDelete:)] )
    {
		[_httpDeleteDelegate  httpDelete:req];
    }
	else
	{
        [self httpUnknownMethod:req];
    }
}

- (void) httpTrace:(UMHTTPRequest *)req
{
	if( [_httpTraceDelegate respondsToSelector:@selector(httpTrace:)] )
    {	
        [_httpTraceDelegate  httpTrace:req];
    }
    else
    {
        [self httpUnknownMethod:req];
    }
}

- (void) httpConnect:(UMHTTPRequest *)req
{
	if( [_httpConnectDelegate respondsToSelector:@selector(httpConnect:)] )
    {
		[_httpConnectDelegate  httpConnect:req];
    }
	else
	{
        [self httpUnknownMethod:req];
    }
}

- (void) httpGetPost:(UMHTTPRequest *)req
{
    UMHTTPPageHandler *handler = [_getPostDict objectForKey:[req.url path]];
    if(handler)
    {
        [handler call:req];
    }
    else if( [_httpGetPostDelegate respondsToSelector:@selector(httpGetPost:)] )
    {
        @try
        {
    		[_httpGetPostDelegate  httpGetPost:req];
        }
        @catch(NSException *ex)
        {
            [req setResponsePlainText:ex.userInfo[@"sysmsg"]];
        }    
    }
	else
    {
        [self httpUnknownMethod:req];
    }
}

- (void) httpUnknownMethod:(UMHTTPRequest *) req;
{
    [req setNotFound];

    /*
     NSString ("HTTP/1.1 302 Found
Date: Mon, 29 Aug 2011 12:50:51 GMT
Server: Apache/2.2.19 (Unix) mod_ssl/2.2.19 OpenSSL/0.9.8r DAV/2 PHP/5.3.6 with Suhosin-Patch
Location: https:///
    Content-Length: 323
Connection: close
    Content-Type: text/html; charset=iso-8859-1
     */
}

- (void) addPageHandler:(UMHTTPPageHandler *)h
{
    [_getPostDict setObject:h forKey:[h path]];
}

- (void) setPrivateKeyFile:(NSString *)filename
{
    _privateKeyFile = filename;
    _privateKeyFileData = [NSData dataWithContentsOfFile:filename];

}

- (void) setCertificateFile:(NSString *)filename
{
    _certFile = filename;
    _certFileData = [NSData dataWithContentsOfFile:filename];

}

- (UMHTTPAuthenticationStatus) httpAuthenticateRequest:(UMHTTPRequest *) req realm:(NSString **)realm
{
    if(_authenticateRequestDelegate)
    {
        if([_authenticateRequestDelegate respondsToSelector:@selector(httpAuthenticateRequest:realm:)])
        {
            return [_authenticateRequestDelegate httpAuthenticateRequest:req realm:realm];
        }
    }
    return UMHTTP_AUTHENTICATION_STATUS_NOT_REQUESTED;
}
@end



