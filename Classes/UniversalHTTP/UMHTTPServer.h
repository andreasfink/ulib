//
//  UMHTTPServer.h
//  UniversalHTTP
//
//  Created by Andreas Fink on 30.12.08.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"

#import "UMHTTPServerAuthorizeResult.h"
#import "UMHTTPAuthenticationStatus.h"
#import "UMSocketDefs.h"
#include <sys/types.h>
#include <netinet/in.h>

@class UMHTTPRequest;
@class UMSocket;
@class UMHTTPConnection;
@class UMTaskQueue;
@class UMSynchronizedArray;
#define	UMHTTP_DEFAULT_PORT	8080

typedef enum UMHTTPServerStatus
{
	UMHTTPServerStatus_notRunning = 0,
	UMHTTPServerStatus_startingUp,
	UMHTTPServerStatus_running,
	UMHTTPServerStatus_shuttingDown,
	UMHTTPServerStatus_shutDown,
	UMHTTPServerStatus_failed,
} UMHTTPServerStatus;


@protocol UMHTTPServerAuthorizeConnectionDelegate <NSObject>
- (UMHTTPServerAuthorizeResult)	httpAuthorizeConnection:(UMSocket *)sock;
@end

@protocol UMHTTPServerAuthenticateRequestDelegate <NSObject>
- (UMHTTPAuthenticationStatus) httpAuthenticateRequest:(UMHTTPRequest *)req realm:(NSString **)realm;
@end

@protocol UMHTTPServerHttpOptionsDelegate <NSObject>
- (void)  httpOptions:(UMHTTPRequest *)req;
@end

@protocol UMHTTPServerHttpGetDelegate <NSObject>
- (void)  httpGet:(UMHTTPRequest *)req;
@end

@protocol UMHTTPServerHttpHeadDelegate <NSObject>
- (void)  httpHead:(UMHTTPRequest *)req;
@end

@protocol UMHTTPServerHttpPostDelegate <NSObject>
- (void)  httpPost:(UMHTTPRequest *)req;
@end

@protocol UMHTTPServerHttpPutDelegate <NSObject>
- (void)  httpPut:(UMHTTPRequest *)req;
@end

@protocol UMHTTPServerHttpDeleteDelegate <NSObject>
- (void)  httpDelete:(UMHTTPRequest *)req;
@end

@protocol UMHTTPServerHttpTraceDelegate <NSObject>
- (void)  httpTrace:(UMHTTPRequest *)req;
@end

@protocol UMHTTPServerHttpConnectDelegate <NSObject>
- (void)  httpConnect:(UMHTTPRequest *)req;
@end

@protocol UMHTTPServerHttpGetPostDelegate <NSObject>
- (void)  httpGetPost:(UMHTTPRequest *)req;
@end

@class UMSleeper;
@class UMHTTPPageHandler;

/*!
 @class UMHTTPServer
 @brief  UMHTTPServer is a builtin webserver

 to start a webserver, instantiate UMHTTPServer and initialize it with initWithPort:. 
 Set its httpGetPostDelegate to a object which will respond to the web requests and simply call the method start.
*/

/*
  the implementation is like this:

 1. There is a mainListener thread running doing nothing else than listening on the port.
 If there is a new connection coming in, it is creating a connection object, add it to the connections array
 and fires of a listenerThread to sit on the tcp stream;

 2. the connectionListener thread does sit on the socket and constantly reads. If there is a complete request
 which came in, it will pass it on to requests queue and calls the delegate for http processing. After he's done
 the response is being sent and the connection might be closed depending of its HTTP/1.1 or HTTP/1.0.

*/

@interface UMHTTPServer : UMObject
{
	UMSocket			*listenerSocket;		/* this is the main listener socket */

	NSMutableArray		*connections;			/*!< list of UMHTTPConnection objects containing the corresponding reading sockets */
	NSMutableArray		*terminatedConnections;	/*!< list of UMHTTPConnection objects containing the corresponding reading sockets */
	NSString			*serverName;			/*!< WebServer HTTP Server: name */

	NSLock				*lock;
    NSLock              *sslLock;
	UMSleeper			*sleeper;

	UMHTTPServerStatus	_status;
	UMSocketError		lastErr;
	BOOL				listenerRunning;
	NSMutableDictionary *getPostDict;
	NSOperationQueue	*httpOperationsQueue;
	NSString            *name;
    int                 receivePollTimeoutMs;
    NSString            *advertizeName;
    BOOL                enableSSL;
    UMTaskQueue         *_taskQueue;
	//
	// the delegates for authorisation
	//
	
	id	<UMHTTPServerAuthorizeConnectionDelegate>	authorizeConnectionDelegate; /*!< this delegate gets called upon a new incoming connection to verify if the calling IP is allowed to connect. */
	id	<UMHTTPServerAuthenticateRequestDelegate>	authenticateRequestDelegate;

	//
	// delegates for HTTP methods
	//
	id	<UMHTTPServerHttpOptionsDelegate>	httpOptionsDelegate;
	id	<UMHTTPServerHttpGetDelegate>		httpGetDelegate;
	id	<UMHTTPServerHttpHeadDelegate>		httpHeadDelegate;
	id	<UMHTTPServerHttpPostDelegate>		httpPostDelegate;
	id	<UMHTTPServerHttpPutDelegate>		httpPutDelegate;
	id	<UMHTTPServerHttpDeleteDelegate>	httpDeleteDelegate;
	id	<UMHTTPServerHttpTraceDelegate>		httpTraceDelegate;
	id	<UMHTTPServerHttpConnectDelegate>	httpConnectDelegate;
	id	<UMHTTPServerHttpGetPostDelegate>	httpGetPostDelegate;

    NSString *privateKeyFile;
    NSData *privateKeyFileData;

    NSString *certFile;
    NSData *certFileData;

    UMSynchronizedArray *pendingRequests;
}

@property(readwrite,strong)		NSString *serverName;
@property(readwrite,assign,atomic)		UMHTTPServerStatus  status;

//
// the delegates for authorisation
//
@property(readwrite, strong)	id	<UMHTTPServerAuthorizeConnectionDelegate>	authorizeConnectionDelegate;
@property(readwrite, strong)	id	<UMHTTPServerAuthenticateRequestDelegate>	authenticateRequestDelegate;

//
// delegates for HTTP methods
//
@property(readwrite, strong)	id	<UMHTTPServerHttpOptionsDelegate>	httpOptionsDelegate;
@property(readwrite, strong)	id	<UMHTTPServerHttpGetDelegate>		httpGetDelegate;
@property(readwrite, strong)	id	<UMHTTPServerHttpHeadDelegate>		httpHeadDelegate;
@property(readwrite, strong)	id	<UMHTTPServerHttpPostDelegate>		httpPostDelegate;
@property(readwrite, strong)	id	<UMHTTPServerHttpPutDelegate>		httpPutDelegate;
@property(readwrite, strong)	id	<UMHTTPServerHttpDeleteDelegate>	httpDeleteDelegate;
@property(readwrite, strong)	id	<UMHTTPServerHttpTraceDelegate>		httpTraceDelegate;
@property(readwrite, strong)	id	<UMHTTPServerHttpConnectDelegate>	httpConnectDelegate;
@property(readwrite, strong)	id	<UMHTTPServerHttpGetPostDelegate>	httpGetPostDelegate;
@property(readwrite, strong)    NSString *name;
@property(readwrite, strong)    NSString *advertizeName;


@property(readonly)				UMSocket	*listenerSocket;
@property(readwrite,assign)     BOOL    enableSSL;
@property(readwrite,strong,atomic)     UMTaskQueue *taskQueue;
@property(readwrite,strong,atomic)      UMSynchronizedArray *pendingRequests;

- (id)init;
- (id)initWithPort:(in_port_t) port;
- (id)initWithPort:(in_port_t) port socketType:(UMSocketType) type;

- (id)initWithPort:(in_port_t)port
        socketType:(UMSocketType)type
               ssl:(BOOL)doSSL
        sslKeyFile:(NSString *)keyFile
       sslCertFile:(NSString *)certFile;

- (id) initWithPort:(in_port_t)port socketType:(UMSocketType)type ssl:(BOOL)doSSL sslKeyFile:(NSString *)sslKeyFile sslCertFile:(NSString *)sslCertFile taskQueue:(UMTaskQueue *)tq;

- (UMSocketError) start;
- (void) mainListener;
- (UMHTTPServerAuthorizeResult) authorizeConnection:(UMSocket *) socket;
- (void) stop;

- (void) connectionDone:(UMHTTPConnection *) con;

- (void) httpOptions:(UMHTTPRequest *) req;
- (void) httpGet:(UMHTTPRequest *) req;
- (void) httpHead:(UMHTTPRequest *) req;
- (void) httpPost:(UMHTTPRequest *) req;
- (void) httpPut:(UMHTTPRequest *) req;
- (void) httpDelete:(UMHTTPRequest *) req;
- (void) httpTrace:(UMHTTPRequest *) req;
- (void) httpConnect:(UMHTTPRequest *) req;

- (void) httpGetPost:(UMHTTPRequest *) req;
- (void) httpUnknownMethod:(UMHTTPRequest *) req;
- (void) addPageHandler:(UMHTTPPageHandler *)h;

- (void) setPrivateKeyFile:(NSString *)filename;
- (void) setCertificateFile:(NSString *)filename;
- (UMHTTPAuthenticationStatus) httpAuthenticateRequest:(UMHTTPRequest *) req realm:(NSString **)realm;

@end





