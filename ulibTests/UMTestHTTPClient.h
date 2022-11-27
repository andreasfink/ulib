//
//  UMTestHTTPClient.h
//  ulib
//
//  Created by Aarno Syvänen on 27.04.12.
//  //  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UMObject.h"

#include <regex.h>

/*
 * Maximum number of HTTP redirections to follow. Making this infinite
 * could cause infinite looping if the redirections loop.
 */
#define HTTP_MAX_FOLLOW 5

/*
 * Default port to connect to for HTTP connections.
 */
enum { HTTP_PORT = 80,
    HTTPS_PORT = 443 };

/*
 * Well-known return values from HTTP servers. This is a complete
 * list as defined by the W3C in RFC 2616, section 10.4.3.
 */
typedef enum {
    HTTP_CONTINUE                           = 100,
    HTTP_SWITCHING_PROTOCOLS                = 101,
    HTTP_OK                                 = 200,
    HTTP_CREATED                            = 201,
    HTTP_ACCEPTED                           = 202,
    HTTP_NON_AUTHORATIVE_INFORMATION        = 203,
    HTTP_NO_CONTENT                         = 204,
    HTTP_RESET_CONTENT                      = 205,
    HTTP_PARTIAL_CONTENT                    = 206,
    HTTP_MULTIPLE_CHOICES                   = 300,
    HTTP_MOVED_PERMANENTLY                  = 301,
    HTTP_FOUND                              = 302,
    HTTP_SEE_OTHER                          = 303,
    HTTP_NOT_MODIFIED                       = 304,
    HTTP_USE_PROXY                          = 305,
    /* HTTP 306 is not used and reserved */
    HTTP_TEMPORARY_REDIRECT                 = 307,
    HTTP_BAD_REQUEST                        = 400,
    HTTP_UNAUTHORISED                       = 401,
    HTTP_PAYMENT_REQUIRED                   = 402,
    HTTP_FORBIDDEN                          = 403,
    HTTP_NOT_FOUND                          = 404,
    HTTP_BAD_METHOD                         = 405,
    HTTP_NOT_ACCEPTABLE                     = 406,
    HTTP_PROXY_AUTHENTICATION_REQUIRED      = 407,
    HTTP_REQUEST_TIMEOUT                    = 408,
    HTTP_CONFLICT                           = 409,
    HTTP_GONE                               = 410,
    HTTP_LENGTH_REQUIRED                    = 411,
    HTTP_PRECONDITION_FAILED                = 412,
    HTTP_REQUEST_ENTITY_TOO_LARGE           = 413,
    HTTP_REQUEST_URI_TOO_LARGE              = 414,
    HTTP_UNSUPPORTED_MEDIA_TYPE             = 415,
    HTTP_REQUESTED_RANGE_NOT_SATISFIABLE    = 416,
    HTTP_EXPECTATION_FAILED                 = 417,
    HTTP_INTERNAL_SERVER_ERROR              = 500,
    HTTP_NOT_IMPLEMENTED                    = 501,
    HTTP_BAD_GATEWAY                        = 502,
    HTTP_SERVICE_UNAVAILABLE                = 503,
    HTTP_GATEWAY_TIMEOUT                    = 504,
    HTTP_HTTP_VERSION_NOT_SUPPORTED         = 505
} http_response_codes;

/*
 * Groupings of the status codes listed above.
 * See the http_status_class() function.
 */

typedef enum _http_status {
    HTTP_STATUS_PROVISIONAL = 100,
    HTTP_STATUS_SUCCESSFUL = 200,
    HTTP_STATUS_REDIRECTION = 300,
    HTTP_STATUS_CLIENT_ERROR = 400,
    HTTP_STATUS_SERVER_ERROR = 500,
    HTTP_STATUS_UNKNOWN = 0
} _httpStatus;


typedef enum _state {
    connecting,
    requestNotSent,
    readingStatus,
    readingEntity,
    transactionDone
} _state;

typedef enum _run_status {
    limbo = -1,
    running = -2,
    terminating = -3
} _runStatus;

@class UMHTTPCaller, UMTestHTTPEntity, UMSocket, TestMutableArray, UMConnPool;

@interface UMTestHTTPClient : UMObject
{
    UMHTTPCaller *caller;
    _runStatus runStatus;
    _httpStatus httpStatus;
    void *requestId;
    int method;             /* uses enums from http.h for the HTTP methods */
    NSString *url;            /* the full URL, including scheme, host, etc. */
    NSString *uri;            /* the HTTP URI path only */
    NSMutableArray *requestHeaders;
    NSString *requestBody;   /* NULL for GET or HEAD, non-NULL for POST */
    _state state;
    int persistent;
    UMTestHTTPEntity *response; /* Can only be NULL if status < 0 */
    UMSocket *__weak sock;
    NSString *host;           /* the server host */
    long port;                /* The server port */
    int followRemaining;
    NSString *certkeyFile;
    int ssl;
    NSString *username;   /* For basic authentication */
    NSString *password;
    NSString *httpInteface; /* Which interface to use for outgoing HTTP requests. */
    long timeout;
@private
    NSThread *sender;
    UMConnPool *pool;
    NSString *httpInterface;
    TestMutableArray *pendingRequests;
    NSLock *clientThreadLock;
    volatile sig_atomic_t client_threads_are_running;
    /*
     * The implemented HTTP method strings
     * Order is sequenced by the enum in the header
     */
    NSArray *httpMethods;
    NSLock *proxyMutex;
    NSString *proxyHostname;
    int proxyPort;
    int proxySsl;
    NSString *proxyUsername;
    NSString *proxyPassword;
    NSMutableArray *proxyExceptions;
    regex_t *proxyExceptionsRegex;
    NSString *subsection;
}

@property (readwrite,weak) UMSocket *sock;
@property (readwrite) UMHTTPCaller *caller;
@property (readwrite,assign) void *requestId;
@property (readwrite,assign) _state state;
@property (readwrite,assign) _httpStatus httpStatus;
@property (readwrite,assign) _runStatus runStatus;
@property (readwrite,strong) NSString *url;
@property (readwrite,strong) UMTestHTTPEntity *response;
@property (readwrite) TestMutableArray *pendingRequests;
@property (readwrite,strong) NSString *host;
@property (readwrite,assign) long port;
@property (readwrite,strong) NSString *username;
@property (readwrite,strong) NSString *password;
@property (readwrite,assign) int method;
@property (readwrite,assign) long timeout;
@property (readwrite,strong) NSThread *sender;
@property (readwrite,strong) UMConnPool *pool;
@property (readwrite,strong) NSString *httpInterface;
@property (readwrite,strong) NSLock *clientThreadLock;
@property (readwrite,assign) volatile sig_atomic_t client_threads_are_running;
@property (readwrite,strong) NSArray *httpMethods;
@property (readwrite,strong) NSLock *proxyMutex;
@property (readwrite,strong) NSString *proxyHostname;
@property (readwrite,assign) int proxyPort;
@property (readwrite,assign) int proxySsl;
@property (readwrite,strong) NSString *proxyUsername;
@property (readwrite,strong) NSString *proxyPassword;
@property (readwrite,strong) NSMutableArray *proxyExceptions;
@property (readwrite,strong) NSString *subsection;
@property (readwrite,strong) NSString *uri;
@property (readwrite,strong) NSMutableArray *requestHeaders;
@property (readwrite,strong) NSString *requestBody;
@property (readwrite,assign) int persistent;
@property (readwrite,assign) int followRemaining;
@property (readwrite,strong) NSString *certkeyFile;
@property (readwrite,assign) int ssl;

- (UMTestHTTPClient *)init;

- (UMTestHTTPClient *)initWithCaller:(UMHTTPCaller *)c withMethod:(int)m withURL:(NSString *)u
        withHeaders:(NSMutableArray *)h withBody:(NSString *)b followRedirections:(int)follow
        withCertificate:(NSString *)ck;

- (UMTestHTTPClient *)copySalient;

- (NSString *)description;

- (void)addRequest:(UMTestHTTPClient *)req;

- (void)addRequestUnlocked:(UMTestHTTPClient *)req;

-(void)startClientThreads;

/**
 * Define timeout in seconds for which HTTP client will wait for
 * response. Set -1 to disable timeouts.
 */
-(void)setClientTimeout:(long)timeout;


/*
 * Functions for controlling proxy use. useProxyWithHost sets the proxy to
 * use; if another proxy was already in use, it is closed and forgotten
 * about as soon as all existing requests via it have been served.
 *
 * closeProxy closes the current proxy connection, after any
 * pending requests have been served.
 */
-(void)useProxyWithHost:(NSString *)hostname withPort:(int)port enableSSL:(BOOL)ssl withExceptions:(NSMutableArray *)exceptions withUsername:(NSString *)username withPassword:(NSString *)password withRegexExceptions:(NSString *)exceptions_regex;
-(void)closeProxy;

/*
 * Start an HTTP request. It will be completed in the background, and
 * the result will eventually be received by receiveResultReturningStatus.
 * receiveResultReturningStatus will return the id parameter passed to this function,
 * and the caller can use this to keep track of which request and which
 * response belong together. If id is nil, it is changed to a non-nil
 * value (nil replies from receiveResultReturningStatus are reserved for cases
 * when it doesn't return a reply).
 *
 * If `body' is nil, it is a GET request, otherwise as POST request.
 * If `follow' is true, HTTP redirections are followed, otherwise not.
 *
 * 'certkeyfile' defines a filename where openssl looks for a PEM-encoded
 * certificate and a private key, if openssl is compiled in and an https
 * URL is used. It can be nil, in which case none is used and thus there
 * is no ssl authentication.´
 */
-(UMTestHTTPClient *) startRequestWithMethod:(int)method
                                  withCaller:(UMHTTPCaller *)caller
                                     withURL:(NSString *)url
                                 withHeaders:(NSMutableArray *)headers
                                    withBody:(NSString *)body
                          followRedirections:(int) follow
                                      withId:(void *)hid
                             withCertificate:(NSString *)certkeyfile
                                    withHost:(NSString *)host
                                    withPort:(long)port
                                withUsername:(NSString *)username
                                withPassword:(NSString *)password;

/*
 * Get the result of a GET or a POST request. Returns either the id pointer
 * (the one passed to startRequestWithMethod if non-nil) or nil if
 *  [caller signalSnutdown] has been called and there are no queued results.
 */
- (void *)receiveResultReturningStatus:(int *)status URL:(NSString **)final_url headers:(NSMutableArray **)headers body:(NSString **)body doBlock:(BOOL)blocking;

@end
