//
//  UMSocket.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMSocket.h"
#import "UMLogFeed.h"
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>
#include <poll.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <netdb.h>

#import "UMLock.h"
#import "NSData+UMSocket.h"
#import "UMAssert.h"
#import "UMFileTrackingMacros.h"

#import "UMUtil.h" /* for UMBacktrace */

#if defined(HAVE_OPENSSL)
#include <openssl/opensslconf.h>
#include <openssl/ssl.h>
#include <openssl/err.h>
#endif

typedef unsigned long (*CRYPTO_CALLBACK_PTR)(void);
static void crypto_threadid_callback(CRYPTO_THREADID *ctid);

//#define SCTP_IN_KERNEL 1
//#define SCTP_IN_USERSPACE 1
//#define FINK_DEBUG  1

#ifdef SCTP_IN_KERNEL
#include <netinet/sctp.h>
//#include <netinet/sctp_uio.h>
#endif

#ifdef	SCTP_IN_USERSPACE
#include "/usr/local/include/usrsctp.h"
#endif

#ifdef SCTP_IN_KERNEL
#define	SCTP_SUPPORTED	1
#endif

#ifdef SCTP_IN_USERSPACE
#define	SCTP_SUPPORTED	1
#endif

#ifndef	IPPROTO_SCTP
#define	IPPROTO_SCTP	132
#endif			

#ifdef __APPLE__
#define HAS_SOCKADDR_LEN    1
#else
#ifdef	LINUX
#undef  HAS_SOCKADDR_LEN
#else
#error  We dont know if this platform needs HAS_SOCKADDR_LEN or not
#endif
#endif

#import "UMHost.h"

#define	UMBLOCK_READ_SIZE	1024
#define	EMPTYSTRINGFORNIL(a)	(a?a:@"")
#define	EMPTYIPFORNIL(a)		((a) ? (a) : @"0.0.0.0")

static SSL_CTX *global_client_ssl_context = NULL;
static SSL_CTX *global_server_ssl_context = NULL;

typedef struct CRYPTO_dynlock_value
{
    void *umlock_ptr;
} CRYPTO_dynlock_value;

static CRYPTO_dynlock_value *dyn_create_function(const char *file, int line);
static void dyn_lock_function(int mode, struct CRYPTO_dynlock_value *l, const char *file, int line);
static void dyn_destroy_function(struct CRYPTO_dynlock_value *l, const char *file, int line);
struct usocket;
typedef void *umlock_c_pointer;
static umlock_c_pointer *ssl_static_locks;
static void openssl_locking_function(int mode, int n, const char *file, int line);

#ifdef SCTP_IN_USERSPACE

int receive_usrsctp_cb(struct usocket *sock, union sctp_sockstore addr, void *data,
                  size_t datalen, struct sctp_rcvinfo rxinfo, int flags, void *ulp_info);
int send_usrsctp_cb(struct usocket *sock, uint32_t sb_free);

// maybe using     __attribute__((weak_import)); ?
struct usocket *usrsctp_socket(int domain, int type, int protocol,
               int (*receive_cb)(struct usocket *sock, union sctp_sockstore addr, void *data,
                                 size_t datalen, struct sctp_rcvinfo, int flags, void *ulp_info),
               int (*send_cb)(struct usocket *sock, uint32_t sb_free),
               uint32_t sb_threshold,
               void *ulp_info);

int usrsctp_setsockopt(struct usocket *so,
                   int level,
                   int option_name,
                   const void *option_value,
                   socklen_t option_len);

#endif

static int SSL_smart_shutdown(SSL *ssl);

static int SSL_smart_shutdown(SSL *ssl)
{
    int i;
    int rc;
    
    /*
     * Repeat the calls, because SSL_shutdown internally dispatches through a
     * little state machine. Usually only one or two interation should be
     * needed, so we restrict the total number of restrictions in order to
     * avoid process hangs in case the client played bad with the socket
     * connection and OpenSSL cannot recognize it.
     */
    rc = 0;
    for (i = 0; i < 4 /* max 2x pending + 2x data = 4 */; i++)
    {
        if ((rc = SSL_shutdown((SSL *)ssl)))
        {
            break;
        }
    }
    return rc;
}

@implementation UMSocket

@synthesize type;
@synthesize direction;
@synthesize status;
@synthesize localHost;
@synthesize remoteHost;
//@synthesize connectedLocalAddress;
//@synthesize connectedRemoteAddress;
@synthesize requestedLocalPort;
@synthesize requestedRemotePort;
@synthesize connectedLocalPort;
@synthesize connectedRemotePort;
//@synthesize sock;
@synthesize isBound;
@synthesize isListening;
@synthesize isConnecting;
@synthesize isConnected;
@synthesize receiveBuffer;
@synthesize lastError;
@synthesize isNonBlocking;
@synthesize reportDelegate;
@synthesize name;
@synthesize hasSocket;
@synthesize advertizeName;
@synthesize advertizeType;
@synthesize advertizeDomain;
@synthesize cryptoStream;
@synthesize useSSL;
@synthesize sslActive;

@synthesize serverSideCertFilename;
@synthesize serverSideKeyFilename;
@synthesize serverSideCertData;
@synthesize serverSideKeyData;

- (NSString *)connectedRemoteAddress
{
    return _connectedRemoteAddress;
}

- (void)setConnectedRemoteAddress:(NSString *)s
{
    _connectedRemoteAddress = s;
}

- (NSString *)connectedLocalAddress
{
    return _connectedLocalAddress;
}

- (void)setConnectedLocalAddress:(NSString *)s
{
    _connectedLocalAddress = s;
}


- (int)sock
{
    return _sock;
}

- (void)setSock:(int)s
{
    if((hasSocket) && (_sock >=0))
    {
        TRACK_FILE_CLOSE(_sock);
        close(_sock);
#if !defined(TARGET_OS_WATCH)
        [netService stop];
        netService=NULL;
#endif
    }
    _sock=s;
    hasSocket=1;
}

+ (NSString *)statusDescription:(UMSocketStatus)s;
{
	switch(s)
	{
	case UMSOCKET_STATUS_FOOS:
		return @"foos";
	case UMSOCKET_STATUS_OFF:
		return @"off";
	case UMSOCKET_STATUS_OOS:
		return @"oos";
	case UMSOCKET_STATUS_IS:
		return @"is";
	}
	return @"unknown";	
}

+ (NSString *)socketTypeDescription:(UMSocketType)t
{
	switch(t)
	{
		case UMSOCKET_TYPE_NONE:
			return @"none";
		case UMSOCKET_TYPE_TCP4ONLY:
			return @"tcp4only";
		case UMSOCKET_TYPE_TCP6ONLY:
			return @"tcp6only";
		case UMSOCKET_TYPE_TCP:
			return @"tcp";
		case UMSOCKET_TYPE_UDP4ONLY:
			return @"udp4only";
		case UMSOCKET_TYPE_UDP6ONLY:
			return @"udp6only";
		case UMSOCKET_TYPE_UDP:
			return @"udp";
		case UMSOCKET_TYPE_SCTP:
			return @"sctp";
		case UMSOCKET_TYPE_SCTP4ONLY:
			return @"sctp4only";
		case UMSOCKET_TYPE_SCTP6ONLY:
			return @"sctp6only";
		case UMSOCKET_TYPE_USCTP:
			return @"usctp";
		case UMSOCKET_TYPE_USCTP4ONLY:
			return @"usctp4only";
		case UMSOCKET_TYPE_USCTP6ONLY:
			return @"usctp6only";
		case UMSOCKET_TYPE_DNSTUN:
			return @"dtun";
		case UMSOCKET_TYPE_UNIX:
			return @"unix";
		case UMSOCKET_TYPE_MEMORY:
			return @"memory";
		case UMSOCKET_TYPE_SERIAL:
			return @"serial";
	}
	return @"unknown";
}

- (BOOL)	isTcpSocket
{
	if((type==UMSOCKET_TYPE_TCP4ONLY) || (type==UMSOCKET_TYPE_TCP6ONLY) || (type==UMSOCKET_TYPE_TCP))
		return YES;
	return NO;
}

- (BOOL)	isUdpSocket
{
	if((type==UMSOCKET_TYPE_UDP4ONLY) || (type==UMSOCKET_TYPE_UDP6ONLY) || (type==UMSOCKET_TYPE_UDP))
	   return YES;
	return NO;
}
		   
- (BOOL)	isSctpSocket
{
	if((type==UMSOCKET_TYPE_SCTP4ONLY) || (type==UMSOCKET_TYPE_SCTP6ONLY) || (type==UMSOCKET_TYPE_SCTP) ||
	   (type==UMSOCKET_TYPE_USCTP4ONLY) || (type==UMSOCKET_TYPE_USCTP6ONLY) || (type==UMSOCKET_TYPE_USCTP))
		return YES;
	return NO;
}

- (BOOL)	isUserspaceSocket
{
	if((type==UMSOCKET_TYPE_USCTP4ONLY) || (type==UMSOCKET_TYPE_USCTP6ONLY) || (type==UMSOCKET_TYPE_USCTP))
		return YES;
	return NO;
}

+ (NSString *)directionDescription:(UMSocketConnectionDirection)d
{
	switch(d)
	{
		case UMSOCKET_DIRECTION_OUTBOUND:
			return @"outbound";
		case UMSOCKET_DIRECTION_INBOUND:
			return @"inbound";
		case UMSOCKET_DIRECTION_PEER:
			return @"peer";
		default:
			return @"unknown";
	}
	return @"unknown";
}

- (NSString *)description
{
	[self updateName];
	return [NSString stringWithString:name];
}

- (NSString *)fullDescription
{
    NSString *typeDesc = [UMSocket socketTypeDescription:type];
    NSString *directionDesc = [UMSocket directionDescription:direction];
    NSString *statusDesc = [UMSocket statusDescription:status];
    NSString *localHostDesc = [localHost description];
    NSString *remoteHostDesc = [remoteHost description];
    
	[self updateName];

    NSString* l0 = [NSString localizedStringWithFormat:@"Name:                 %@", name ? name : @"not set"];
    NSString* l1 = [NSString localizedStringWithFormat:@"SocketType:           %@", typeDesc ? typeDesc : @"none available "];
    NSString* l2 = [NSString localizedStringWithFormat:@"Connection Direction: %@", directionDesc ? directionDesc : @"none available"];
    NSString* l3 = [NSString localizedStringWithFormat:@"Status:               %@", statusDesc ? statusDesc : @"none available"];
    NSString* l4 = [NSString localizedStringWithFormat:@"Local Host:           %@", localHostDesc ? localHostDesc : @"none available"];
    NSString* l5 = [NSString localizedStringWithFormat:@"Remote Host:          %@", remoteHostDesc ? remoteHostDesc : @"none available"];
    NSString* l6 = [NSString localizedStringWithFormat:@"Local Port:           %d", connectedLocalPort];
    NSString* l7 = [NSString localizedStringWithFormat:@"Remote Port:          %d", connectedRemotePort];
    NSString* l8 = [NSString localizedStringWithFormat:@"Socket:               %d", _sock];
    return [NSString stringWithFormat:@"%@\n%@\n%@\n%@\n%@\n%@\n%@\n%@\n%@\n",l0,l1,l2,l3,l4,l5,l6,l7,l8];
}

- (void) dealloc
{
    if(ssl)
    {
        SSL_smart_shutdown((SSL *)ssl);
        SSL_free((SSL *)ssl);
        ssl = NULL;
    }
    /*
    if (peer_certificate != NULL)
    {
        X509_free((X509 *)peer_certificate);
        peer_certificate = NULL;
    }
*/
    if((hasSocket != 0) && (_sock >= 0))
    {
        NSLog(@"deallocating a connection which has an open socket");
        TRACK_FILE_CLOSE(_sock);
        close(_sock);
        _sock = -1;
    }
}

- (UMSocket *) init
{
    self = [super init];
    if(self)
    {
        _sock = -1;
        cryptoStream = [[UMCrypto alloc] init];
    }
    return self;
}


- (UMSocket *) initWithType:(UMSocketType)t
{
    self = [super init];
    if (self)
    {
        int reuse = 1;
        int eno = 0;
        rx_crypto_enable = 0;
        tx_crypto_enable = 0;
        cryptoStream = [[UMCrypto alloc] init];
        
        type = t;
        _sock = -1;
        switch(type)
        {
            case UMSOCKET_TYPE_TCP4ONLY:
                _family=AF_INET;
                _sock = socket(_family, SOCK_STREAM, IPPROTO_TCP);
                eno = errno;
                TRACK_FILE_SOCKET(_sock,@"tcp");
                break;
            case UMSOCKET_TYPE_TCP6ONLY:
                _family=AF_INET6;
                _sock = socket(_family, SOCK_STREAM, IPPROTO_TCP);
                eno = errno;
                TRACK_FILE_SOCKET(_sock,@"tcp");
                break;
            case UMSOCKET_TYPE_TCP:
                _family=AF_INET6;
                _sock = socket(_family, SOCK_STREAM, IPPROTO_TCP);
                eno = errno;
                TRACK_FILE_SOCKET(_sock,@"tcp");
                if(_sock < 0)
                {
                    if(eno==EAFNOSUPPORT)
                    {
                        _family=AF_INET;
                        _sock = socket(_family,SOCK_STREAM, IPPROTO_TCP);
                        eno = errno;
                        TRACK_FILE_SOCKET(_sock,@"tcp");
                    }
                }
                break;
            case UMSOCKET_TYPE_UDP4ONLY:
                _family=AF_INET;
                _sock = socket(_family,SOCK_DGRAM, IPPROTO_UDP);
                eno = errno;
                TRACK_FILE_SOCKET(_sock,@"udp");
                break;
            case UMSOCKET_TYPE_UDP6ONLY:
                _family=AF_INET6;
                _sock = socket(_family,SOCK_DGRAM, IPPROTO_UDP);
                eno = errno;
                TRACK_FILE_SOCKET(_sock,@"udp");
                break;
            case UMSOCKET_TYPE_UDP:
                _family=AF_INET6;
                _sock = socket(_family,SOCK_DGRAM, 0);
                eno = errno;
                TRACK_FILE_SOCKET(_sock,@"udp");
                if(_sock < 0)
                {
                    if(eno==EAFNOSUPPORT)
                    {
                        _family=AF_INET;
                        _sock = socket(_family,SOCK_DGRAM, 0);
                        eno = errno;
                        TRACK_FILE_SOCKET(_sock,@"udp");
                    }
                }
                break;
            case UMSOCKET_TYPE_SCTP4ONLY:
                _family=AF_INET;
                _sock = socket(_family,SOCK_STREAM, IPPROTO_SCTP);
                eno = errno;
                TRACK_FILE_SOCKET(_sock,@"sctp");
                break;
            case UMSOCKET_TYPE_SCTP6ONLY:
                _family=AF_INET6;
                _sock = socket(_family,SOCK_STREAM, IPPROTO_SCTP);
                eno = errno;
                TRACK_FILE_SOCKET(_sock,@"sctp");
                break;
#ifdef	SCTP_IN_KERNEL
            case UMSOCKET_TYPE_SCTP:
                _family=AF_INET6;
                _sock = socket(_family,SOCK_STREAM, IPPROTO_SCTP);
                eno = errno;
                TRACK_FILE_SOCKET(_sock,@"sctp");
                if(sock < 0)
                {
                    if(eno==EAFNOSUPPORT)
                    {
                        _family=AF_INET;
                        sock = socket(_family,SOCK_STREAM, IPPROTO_SCTP);
                        eno = errno;
                        TRACK_FILE_SOCKET(_sock,@"sctp");
                        if(sock!=-1)
                        {
                            int flags = 1;
                            setsockopt(sock, IPPROTO_SCTP, SCTP_NODELAY, (char *)&flags, sizeof(flags));
                        }
                    }
                }
                break;
#endif
            default:
                return nil;
        }
        
        if(_sock <0 )
        {
            switch(type)
            {
                case UMSOCKET_TYPE_TCP6ONLY:
                case UMSOCKET_TYPE_TCP4ONLY:
                case UMSOCKET_TYPE_TCP:
                    NSLog(@"[UMSocket: init] socket(IPPROTO_TCP) returns %d errno = %d",_sock,eno);
                    break;
                case UMSOCKET_TYPE_UDP6ONLY:
                case UMSOCKET_TYPE_UDP4ONLY:
                case UMSOCKET_TYPE_UDP:
                    NSLog(@"[UMSocket: init] socket(IPPROTO_UDP) returns %d errno = %d",_sock,eno);
                    break;
#ifdef	SCTP_IN_KERNEL
                case UMSOCKET_TYPE_SCTP4ONLY:
                case UMSOCKET_TYPE_SCTP6ONLY:
                case UMSOCKET_TYPE_SCTP:
                    NSLog(@"[UMSocket: init] socket(IPPROTO_SCTP) returns %d errno = %d",_sock,eno);
                    break;
#endif
                    
                default:
                    break;
            }
            return nil;
        }
        if(_sock >=0)
        {
            hasSocket=1;
            cryptoStream.fileDescriptor = _sock;
        }
        receiveBuffer = [[NSMutableData alloc] init];
        if(reuse)
        {
            if(setsockopt(_sock, SOL_SOCKET, SO_REUSEADDR, (char *) &reuse,sizeof(reuse)) == -1)
            {
                eno = errno;
                NSLog(@"[UMSocket: init] setsockopt(SO_REUSEADDR) sets errno to %d",eno);
            }
        }
    }
    return self;
}

- (UMSocketError) bind
{
    int eno = 0;
#ifdef	SCTP_SUPPORTED
	NSArray				*localAddresses = NULL;
	NSMutableArray			*useableLocalAddresses;
#endif
	struct sockaddr_in	sa;
	struct sockaddr_in6	sa6;
#ifdef  SCTP_SUPPORTED
	int i;
	NSString	*ipAddr;
	char	addressString[256];
	int		err;
#endif
	[self reportStatus:@"bind()"];

	if (isBound == 1)
	{
		[self reportStatus:@"- already bound"];
		return UMSocketError_already_bound;
	}

	localHost				= [[UMHost alloc] initWithLocalhost];
#ifdef	SCTP_SUPPORTED
	localAddresses			= [localHost addresses];
	useableLocalAddresses	= [[NSMutableArray alloc] init];
#endif
	memset(&sa,0x00,sizeof(sa));
	sa.sin_family			= AF_INET;
#ifdef	HAS_SOCKADDR_LEN
	sa.sin_len			= sizeof(struct sockaddr_in);
#endif
	sa.sin_port			= htons(requestedLocalPort);
	sa.sin_addr.s_addr		= htonl(INADDR_ANY);
	memset(&sa6,0x00,sizeof(sa6));
	sa6.sin6_family			= AF_INET6;
#ifdef	HAS_SOCKADDR_LEN
	sa6.sin6_len			= sizeof(struct sockaddr_in);
#endif
	sa6.sin6_port			= htons(requestedLocalPort);
	sa6.sin6_addr			= in6addr_any;
	
	switch(type)
	{
#ifdef	SCTP_SUPPORTED
		case UMSOCKET_TYPE_SCTP:
			for(i=0;i< [localAddresses count];i++)
			{
				memset(&sa,0x00,sizeof(sa));
				sa.sin_family   = AF_INET;
#ifdef	HAS_SOCKADDR_LEN
				sa.sin_len  = sizeof(struct sockaddr_in);
#endif
				sa.sin_port = htons(requestedLocalPort);

				ipAddr = [localAddresses objectAtIndex:i];
				[ipAddr getCString:addressString maxLength:255 encoding:NSUTF8StringEncoding];

				inet_aton(addressString, &sa.sin_addr);
				err = sctp_bindx(sock, (struct sockaddr *)&sa,1,SCTP_BINDX_ADD_ADDR);
				if(!err)
				{
					[useableLocalAddresses addObject:ipAddr];
				}
			}
			
			if( [useableLocalAddresses count] == 0)
			{
				return UMSocketError_sctp_bindx_failed_for_all;
			}
			break;
#endif
		case UMSOCKET_TYPE_TCP4ONLY:
		case UMSOCKET_TYPE_UDP4ONLY:
			if(bind(_sock,(struct sockaddr *)&sa,sizeof(sa)) != 0)
               {
                   eno = errno;
                   goto err;
               }
			break;
		case UMSOCKET_TYPE_TCP6ONLY:
		case UMSOCKET_TYPE_UDP6ONLY:
		case UMSOCKET_TYPE_TCP:
		case UMSOCKET_TYPE_UDP:
			if(bind(_sock,(struct sockaddr *)&sa6,sizeof(sa6)) != 0)
               {
                   eno = errno;
                   goto err;
               }
			break;
		default:
			return [UMSocket umerrFromErrno:EAFNOSUPPORT];
	}
	isBound = 1;
	[self reportStatus:@"isBound=1"];
	return UMSocketError_no_error;
err:
	return [UMSocket umerrFromErrno:eno];
}

- (UMSocketError) openAsync
{
	return 0;
}

- (UMSocketError) listen
{
	return [self listen: 128];
}

- (UMSocketError) listen: (int) backlog
{
	int err;
	
	[self reportStatus:@"caling listen()"];
	if (isListening == 1)
	{
		[self reportStatus:@"- already listening"];
		return UMSocketError_already_listening;
	}
	isListening = 0;

	err = listen(_sock,backlog);
    
	direction = direction | UMSOCKET_DIRECTION_INBOUND;
	if(err)
     {
         int eno = errno;
         return [UMSocket umerrFromErrno:eno];
     }
	isListening = 1;
	[self reportStatus:@"isListening=1"];
	return UMSocketError_no_error;
}


- (UMSocketError) publish
{
#if defined(TARGET_OS_WATCH)
    return UMSocketError_not_supported_operation;
#else
    if(!isListening)
    {
        return UMSocketError_not_listening;
    }
    if(advertizeDomain==NULL)
    {
        return UMSocketError_invalid_advertize_domain;
    }
    if([advertizeType length]==0)
    {
        return UMSocketError_invalid_advertize_type;
    }
    if([advertizeName length]==0)
    {
        return UMSocketError_invalid_advertize_name;
    }

    netService = [[NSNetService alloc] initWithDomain:advertizeDomain
                                         type:advertizeType
                                         name:advertizeName
                                         port:requestedLocalPort];
    [netService scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [netService setDelegate:self];
    [netService publish];
#endif
    return UMSocketError_no_error;
}

- (UMSocketError) unpublish
{
#if defined(TARGET_OS_WATCH)
    return UMSocketError_not_supported_operation;
#else

    [netService stop];
    netService=NULL;
    return UMSocketError_no_error;
#endif
}


#if !defined(TARGET_OS_WATCH)


- (void)netServiceWillPublish:(NSNetService *)sender
{
    //NSLog(@"netServiceWillPublish:");
}

- (void)netServiceDidPublish:(NSNetService *)sender
{
    //NSLog(@"netServiceDidPublish:");
    
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
{
    NSLog(@"netService:didNotPublish:%@",errorDict);

}

- (void)netServiceDidStop:(NSNetService *)sender
{
    //NSLog(@"netServiceDidStop:");
}
#endif


- (UMSocketError) connect
{
    struct sockaddr_in	sa;
    struct sockaddr_in6	sa6;
    char addr[256];
    int err;
    ip_version = 0;
    NSString *address;
    int resolved;
    
    if((_sock < 0) || (!hasSocket))
    {
        isConnecting = 0;
        isConnected = 0;
        return  [UMSocket umerrFromErrno:EBADF];
    }
    
    memset(&sa,0x00,sizeof(sa));
    sa.sin_family		= AF_INET;
#ifdef	HAS_SOCKADDR_LEN
    sa.sin_len			= sizeof(struct sockaddr_in);
#endif
    sa.sin_port         = htons(requestedRemotePort);
    
    memset(&sa6,0x00,sizeof(sa6));
    sa6.sin6_family			= AF_INET6;
#ifdef	HAS_SOCKADDR_LEN
    sa6.sin6_len        = sizeof(struct sockaddr_in6);
#endif
    sa6.sin6_port       = htons(requestedRemotePort);
    
    while((resolved = [remoteHost resolved]) == 0)
        usleep(50000);
    address = [remoteHost address:(UMSocketType)type];
    if (!address)
    {
        NSLog(@"[UMSocket connect] EADDRNOTAVAIL (address not resolved) during connect");
        isConnecting = 0;
        isConnected = 0;
        return UMSocketError_address_not_available;
    }
    
    [address getCString:addr maxLength:255 encoding:NSUTF8StringEncoding];
    //	inet_aton(addr, &sa.sin_addr);
    
    if( inet_pton(AF_INET6, addr, &sa6.sin6_addr) == 1)
    {
        ip_version = 6;
    }
    else if(inet_pton(AF_INET, addr, &sa.sin_addr) == 1)
    {
        ip_version = 4;
    }
    else
    {
        NSLog(@"[UMSocket connect] EADDRNOTAVAIL (unknown IP family) during connect");
        isConnecting = 0;
        isConnected = 0;
        return UMSocketError_address_not_available;
    }
    
    direction = direction | UMSOCKET_DIRECTION_OUTBOUND;
    isConnecting = 1;
    
    [self reportStatus:@"calling connect()"];
    if(ip_version==6)
    {
        err = connect(_sock, (struct sockaddr *)&sa6, sizeof(sa6));
    }
    else if(ip_version==4)
    {
        err = connect(_sock, (struct sockaddr *)&sa, sizeof(sa));
    }
    else
    {
        UMAssert(0,@"[UMSocket connect]: IPversion is not 6 neither 4");
        err = 0;
    }
    if(err)
    {
        
        isConnecting = 0;
        isConnected = 0;
        //		goto err;
    }
    else
    {
        isConnecting = 0;
        isConnected = 1;
        status = UMSOCKET_STATUS_IS;
        NSString *msg = [NSString stringWithFormat:@"socket %d isConnected=1",_sock];
        [self reportStatus:msg];
        return 0;
    }
    //err:
    int eno = errno;
    NSLog(@"[UMSocket connect] failed with errno %d (name %@)", eno, name);
    return [UMSocket umerrFromErrno:eno];
}

- (UMSocket *) copyWithZone:(NSZone *)zone
{
    UMSocket *newsock = [[UMSocket alloc]init];
    
    newsock.type = type;
    newsock.direction =  direction;
    newsock.status=status;
    newsock.localHost = localHost;
    newsock.remoteHost = remoteHost;
    newsock.requestedLocalPort=requestedLocalPort;
    newsock.requestedRemotePort=requestedRemotePort;
    newsock.cryptoStream = [cryptoStream copy];
/* we do not copy the socket on purpose as this is used from accept() */
//	newsock._sock=0;
//   newsock.hasSocket=0;

     newsock.isBound=isBound;
	newsock.isListening=isListening;
	newsock.isConnecting=isConnecting;
	newsock.isConnected=isConnected;	
	return newsock;
}

- (void) setLocalPort:(in_port_t) port
{
	requestedLocalPort = port;
}

- (void) setRemotePort:(in_port_t) port
{
	requestedRemotePort = port;
}

- (in_port_t) localPort
{
	[self updateName];
	return connectedLocalPort;
}

- (in_port_t) remotePort
{
	[self updateName];
	return connectedRemotePort;
}

- (NSString *)getRemoteAddress
{
    [self updateName];
    return self.connectedRemoteAddress;
}

- (void) doInitReceiveBuffer
{
    receiveBuffer = [[NSMutableData alloc] init];
    receivebufpos = 0;
}

- (void) deleteFromReceiveBuffer:(NSUInteger)bytes
{
    long len;
    
    if (bytes > (len = [receiveBuffer length]))
    {
        bytes = (unsigned int)len;
    }
    [receiveBuffer replaceBytesInRange:NSMakeRange(0, bytes) withBytes:nil length:0];
    receivebufpos -= bytes;
    if (receivebufpos < 0)
    {
        receivebufpos = 0;
    }
}

- (UMSocket *) accept:(UMSocketError *)ret
{
    int		newsock = -1;
    UMSocket *newcon =NULL;
    NSString *remoteAddress=@"";
    in_port_t remotePort=0;
    int eno=0;
    

    if( (type == UMSOCKET_TYPE_TCP4ONLY) ||
       (type == UMSOCKET_TYPE_UDP4ONLY) ||
       (type == UMSOCKET_TYPE_SCTP4ONLY))
    {
        struct	sockaddr_in		sa4;
        socklen_t slen4 = sizeof(sa4);
        
        
#ifdef FINK_DEBUG
        NSLog(@"accept ipv4 on %d",_sock);
#endif
        newsock = accept(_sock,(struct sockaddr *)&sa4,&slen4);
        eno = errno;
#ifdef FINK_DEBUG
        NSLog(@"returned  %d, errno=%d",newsock,eno);
#endif
        if(newsock >=0)
        {
            char hbuf[NI_MAXHOST];
            char sbuf[NI_MAXSERV];
            if (getnameinfo((struct sockaddr *)&sa4, slen4, hbuf, sizeof(hbuf), sbuf,
                            sizeof(sbuf), NI_NUMERICHOST | NI_NUMERICSERV))
            {
                remoteAddress = @"ipv4:0.0.0.0";
                remotePort = sa4.sin_port;
            }
            else
            {
                remoteAddress = @(hbuf);
                remoteAddress = [NSString stringWithFormat:@"ipv4:%@", remoteAddress];
                remotePort = sa4.sin_port;
            }
            TRACK_FILE_SOCKET(newsock,remoteAddress);

            newcon.cryptoStream.fileDescriptor = newsock;
        }
    }
    else
    {
        struct	sockaddr_in6		sa6;
        socklen_t slen6 = sizeof(sa6);

#ifdef FINK_DEBUG
        NSLog(@"accept ipv4 on %d",_sock);
#endif
        newsock = accept(_sock,(struct sockaddr *)&sa6,&slen6);
        eno = errno;

#ifdef FINK_DEBUG
        NSLog(@"returned  %d, errno=%d",newsock,eno);
#endif

        if(newsock >= 0)
        {
            char hbuf[NI_MAXHOST], sbuf[NI_MAXSERV];
            if (getnameinfo((struct sockaddr *)&sa6, slen6, hbuf, sizeof(hbuf), sbuf,
                            sizeof(sbuf), NI_NUMERICHOST | NI_NUMERICSERV))
            {
                remoteAddress = @"ipv6:[::]";
                remotePort = sa6.sin6_port;
            }
            else
            {
                remoteAddress = @(hbuf);
                remotePort = sa6.sin6_port;
            }
            /* this is a IPv4 style address packed into IPv6 */
            
            remoteAddress = [UMSocket unifyIP:remoteAddress];
            TRACK_FILE_SOCKET(newsock,remoteAddress);

        }
    }
    if(newsock >= 0)
    {
        newcon = [[UMSocket alloc]init];
        newcon.type = type;
        newcon.direction =  direction;
        newcon.status=status;
        newcon.localHost = localHost;
        newcon.remoteHost = remoteHost;
        newcon.requestedLocalPort=requestedLocalPort;
        newcon.requestedRemotePort=requestedRemotePort;
        newcon.cryptoStream = [[UMCrypto alloc]initWithRelatedSocket:newcon];
        newcon.isBound=NO;
        newcon.isListening=NO;
        newcon.isConnecting=NO;
        newcon.isConnected=YES;
        [newcon setSock: newsock];
        [newcon switchToNonBlocking];
        [newcon doInitReceiveBuffer];
        newcon.connectedRemoteAddress = remoteAddress;
        newcon.connectedRemotePort = remotePort;
        newcon.useSSL = useSSL;
        [newcon updateName];
        [self reportStatus:@"accept () successful"];
        
        /* TODO: start SSL if required here */
        return newcon;
    }
    *ret = [UMSocket umerrFromErrno:eno];
    return nil;
}

- (void) switchToNonBlocking
{
	int flags;
	if(isNonBlocking == 0)
	{
		flags = fcntl(_sock, F_GETFL, 0);
		fcntl(_sock, F_SETFL, flags  | O_NONBLOCK);
#ifdef SCTP_IN_KERNEL
         if(type == UMSOCKET_TYPE_SCTP)
		{
              flags = 1;
              setsockopt(sock, IPPROTO_SCTP, SCTP_NODELAY, (char *)&flags, sizeof(flags));
		}
          else
#endif
        if (type==UMSOCKET_TYPE_USCTP)
          {
#ifdef SCTP_IN_USERSPACE
             if(usrsctp_setsockopt)
             {
                 flags = 1;
                 usrsctp_setsockopt(sock, IPPROTO_SCTP, SCTP_NODELAY, (char *)&flags, sizeof(flags));
             }
#endif
         }
		isNonBlocking = 1;
	}
}

- (void) switchToBlocking
{
	int flags;
	if(isNonBlocking)
	{
		flags = fcntl(_sock, F_GETFL, 0);
		fcntl(_sock, F_SETFL, flags  & ~O_NONBLOCK);
		isNonBlocking = 0;
	}
}

- (void) setIsNonBlocking:(int)i
{
	if(i)
     {
		[self switchToNonBlocking];
     }
	else
     {
		[self switchToBlocking];
     }
}

- (UMSocketError) close
{
    UMSocketError err = UMSocketError_no_error;
    if((hasSocket == 0) || (_sock < 0))
    {
        return err;
    }
#ifdef FINK_DEBUG
    NSLog(@"closing socket %d",_sock);
#endif

    TRACK_FILE_CLOSE(_sock);
    int res = close(_sock);
    if (res)
    {
        int eno = errno;
        err = [UMSocket umerrFromErrno:eno];
    }
    
    _sock=-1;
    hasSocket=0;
    status = UMSOCKET_STATUS_OOS;
    isConnected = 0;
    return err;
}

- (UMSocketError)  sendBytes:(void *)bytes length:(ssize_t)length
{
    ssize_t i;
    int eno = 0;
    
    if(length == 0)
    {
        return UMSocketError_no_error;
    }
    switch(type)
    {
        case UMSOCKET_TYPE_NONE:
            return UMSocketError_no_error;
            break;
            
        case UMSOCKET_TYPE_TCP4ONLY:
        case UMSOCKET_TYPE_TCP6ONLY:
        case UMSOCKET_TYPE_TCP:
            if((_sock < 0) || (hasSocket ==0))
            {
                isConnecting = 0;
                isConnected = 0;
                return [UMSocket umerrFromErrno:EBADF];
            }
            
            if(!isConnected)
            {
                isConnecting = 0;
                isConnected = 0;
                return [UMSocket umerrFromErrno:ECONNREFUSED];
            }
            
            i = [cryptoStream writeBytes:bytes length:length errorCode:&eno];
            if (i != length)
            {
                NSString *msg = [NSString stringWithFormat:@"[UMSocket: sendBytes] socket %d (status %d) returns %d errno = %d",_sock,status, [UMSocket umerrFromErrno:eno],eno];
                [logFeed info:0 inSubsection:@"Universal socket" withText:msg];
                return [UMSocket umerrFromErrno:eno];
            }
            break;
        default:
            return UMSocketError_not_supported_operation;
            break;
    }
    return UMSocketError_no_error;
}

-(UMSocketError) sendMutableData: (NSMutableData *)data
{
    if([data length] == 0)
    {
        return UMSocketError_no_error;
    }
    return [self sendBytes:(void *)[data bytes] length:[data length]];
}

-(UMSocketError) sendData: (NSData *)data
{
    if([data length] == 0)
    {
        return UMSocketError_no_error;
    }
    return [self sendBytes:(void *)[data bytes] length:[data length]];
}

- (UMSocketError) sendCString:(char *)str
{
    if (!str)
    {
        return UMSocketError_no_error;
    }
    return [self sendBytes:(void *)str length:strlen(str)];
}

- (UMSocketError) sendString:(NSString *)str
{
	NSData *data = nil;
	int	ret;
    @autoreleasepool {
	
		data = [str dataUsingEncoding:NSUTF8StringEncoding];
		//NSLog(@"[UMSocket sendString]: SendString: <%@>", str);
		ret =  [self sendBytes:(void *)[data bytes] length:[data length]];
		return ret;
	}
}

- (int) send:(NSMutableData *)data
{
	ssize_t i;
    int eno = 0;
	switch(type)
	{
#if defined(UM_TRANSPORT_SCTP_SUPPORTED)
		case UMSOCKET_TYPE_SCTP:
			[self sendSctp:data withStreamID: 0 withProtocolID: 0]
			break;
#endif
		case UMSOCKET_TYPE_TCP4ONLY:
		case UMSOCKET_TYPE_TCP6ONLY:
		case UMSOCKET_TYPE_TCP:
			
               if((_sock < 0) || (hasSocket ==0))
			{
				isConnecting = 0;
				isConnected = 0;
				return [UMSocket umerrFromErrno:EBADF];
				
			}
			
			if(!isConnected)
			{
				isConnecting = 0;
				isConnected = 0;
				return [UMSocket umerrFromErrno:EINVAL];
			}		
			
			NSLog(@"Sending: %@",data);
			i =	[cryptoStream writeBytes: [data bytes] length:[data length]  errorCode:&eno];
			if (i != [data length])
			{
				return [UMSocket umerrFromErrno:eno];
			}
			break;
		default:
			return [UMSocket umerrFromErrno:EAFNOSUPPORT];
	}
	return 0;
}

- (int) sendSctpBytes:(void *)bytes length:(int)len 
{

	return [self sendSctp: bytes length:len stream:0 protocol:0];
}

- (int) sendSctpNSData:(NSData *)data
{		
	return [self sendSctp:(void *)[data bytes] length:[data length] stream: 0 protocol: 0];
}

- (int) sendSctp:(void *)bytes length:(ssize_t)len  stream:(NSUInteger) streamID protocol:(NSUInteger) protocolID
{
	return UMSocketError_not_supported_operation;
}

- (UMSocketError) waitDataAvailable
{
	return [self dataIsAvailable: -1];
}

- (UMSocketError) dataIsAvailable
{
	return [self dataIsAvailable: 0];
}

- (UMSocketError) dataIsAvailable:(int)timeoutInMs
{
    struct pollfd pollfds[1];
    int ret1;
    int ret2;
    int eno = 0;
    
    
    int events = POLLIN | POLLPRI | POLLERR | POLLHUP | POLLNVAL;
    
#ifdef POLLRDBAND
    events |= POLLRDBAND;
#endif
    
#ifdef POLLRDHUP
    events |= POLLRDHUP;
#endif


    memset(pollfds,0,sizeof(pollfds));
    pollfds[0].fd = _sock;
    pollfds[0].events = events;
    

//    UMAssert(timeoutInMs>0,@"timeout should be larger than 0");
    UMAssert(timeoutInMs<200000,@"timeout should be smaller than 20seconds");
    
    errno = 99;
    ret1 = poll(pollfds, 1, timeoutInMs);
    if (ret1 < 0)
    {
        eno = errno;
        /* error condition */
        if (eno != EINTR)
        {
            ret2 = [UMSocket umerrFromErrno:EBADF];
            return ret2;
        }
        else
        {
            return [UMSocket umerrFromErrno:eno];
        }
    }
    else if (ret1 == 0)
    {
        ret2 = UMSocketError_no_data;
        return ret2;
    }
    else
    {
        eno = errno;
        /* we have some event to handle. */
        ret2 = pollfds[0].revents;
        //NSLog(@"revents are %d", ret2);
        if(ret2 & POLLERR)
        {
            return [UMSocket umerrFromErrno:eno];
        }
        else if(ret2 & POLLHUP)
        {
            return UMSocketError_has_data_and_hup;
        }
        
#ifdef POLLRDHUP
        else if(ret2 & POLLRDHUP)
        {
            return UMSocketError_has_data_and_hup;
        }
#endif
        else if(ret2 & POLLNVAL)
        {
            return [UMSocket umerrFromErrno:eno];
        }
#ifdef POLLRDBAND
        else if(ret2 & POLLRDBAND)
        {
            return UMSocketError_has_data;
        }
#endif
        else if(ret2 & POLLIN)
        {
            return UMSocketError_has_data;
        }
        else if(ret2 & POLLPRI)
        {
            return UMSocketError_has_data;
        }
        /* we get alerted by poll that something happened but no data to read.
            so we either jump out of the timeout or something bad happened which we are not catching */
        return [UMSocket umerrFromErrno:eno];
    }
}

- (UMSocketError) receiveEverythingTo:(NSData **)toData
{
    UMSocketError ret;
    ssize_t actualReadBytes = 0;
	unsigned char chunk[UMBLOCK_READ_SIZE];
    
    *toData = nil;
    int eno = 0;

    if ([receiveBuffer length] == 0)
    {
        
        actualReadBytes = [cryptoStream readBytes:chunk length:sizeof(chunk) errorCode:&eno];
        eno = errno;

        if (actualReadBytes < 0)
        {
            if (eno != EAGAIN)
            {
                return [UMSocket umerrFromErrno:eno];
            }
            else
            {
                return UMSocketError_try_again;
            }
        }
        else if (actualReadBytes == 0)
        {
            return UMSocketError_no_data;
        }
        [receiveBuffer appendBytes:chunk length:actualReadBytes];
        if ([receiveBuffer length] == 0) 
        {
            ret = [UMSocket umerrFromErrno:eno];
            return ret;
        }
    }
    

    *toData = [[receiveBuffer subdataWithRange:NSMakeRange(0, [receiveBuffer length])] mutableCopy];
    [receiveBuffer replaceBytesInRange:NSMakeRange(0, [receiveBuffer length]) withBytes:nil length:0];
    receivebufpos = 0;
        
    return UMSocketError_no_error;
}


- (UMSocketError) receive:(ssize_t)max appendTo:(NSMutableData *)toData
{
	ssize_t wantReadBytes;
	ssize_t actualReadBytes;
	ssize_t remainingBytes;
     UMSocketError ret;
    int eno=0;
    
	unsigned char chunk[UMBLOCK_READ_SIZE];
	
	[self switchToNonBlocking];

	remainingBytes = max;
     while(remainingBytes > 0)
     {
         if(remainingBytes < UMBLOCK_READ_SIZE)
         {
             wantReadBytes = remainingBytes;
         }
         else
         {
             wantReadBytes = UMBLOCK_READ_SIZE;
         }
         actualReadBytes = [cryptoStream readBytes: chunk length:wantReadBytes errorCode:&eno];
         
         if(actualReadBytes < 0)
         {
             if (eno != EAGAIN)
             {
                 ret = [UMSocket umerrFromErrno:EBADF];
                 return ret;
             }
             else
             {
                 ret = UMSocketError_try_again;
                 return ret;
             }
         }
         [toData appendBytes:chunk length:actualReadBytes];
         remainingBytes = remainingBytes - actualReadBytes;
     }
	ret = UMSocketError_no_error;
    return ret;
}

- (void) reportError:(int)err withString: (NSString *)errString
{
	switch(err)
	{
		case EACCES:
			NSLog(@"Error: %d EACCES %@",err,errString);
			break;
		case EADDRINUSE:
			NSLog(@"Error: %d EADDRINUSE %@",err,errString);
			break;
		case EADDRNOTAVAIL:
			NSLog(@"Error: %d EADDRNOTAVAIL %@",err,errString);
			break;
		case EAFNOSUPPORT:
			NSLog(@"Error: %d EAFNOSUPPORT %@",err,errString);
			break;
		case EALREADY:
			NSLog(@"Error: %d EALREADY %@",err,errString);
			break;
		case EBADF:
			NSLog(@"Error: %d EBADF %@",err,errString);
			break;
		case ECONNREFUSED:
			NSLog(@"Error: %d ECONNREFUSED %@",err,errString);
			break;
		case EHOSTUNREACH:
			NSLog(@"Error: %d EHOSTUNREACH %@",err,errString);
			break;
		case EINPROGRESS:
			NSLog(@"Error: %d EINPROGRESS %@",err,errString);
			break;
		case EINTR:
			NSLog(@"Error: %d EINTR %@",err,errString);
			break;
		case EINVAL:
			NSLog(@"Error: %d EINVAL %@",err,errString);
			break;
		case EISCONN:
			NSLog(@"Error: %d EISCONN %@",err,errString);
			break;
		case ENETDOWN:
			NSLog(@"Error: %d ENETDOWN %@",err,errString);
			break;
		case ENETUNREACH:
			NSLog(@"Error: %d ENETUNREACH %@",err,errString);
			break;
		case ENOBUFS:
			NSLog(@"Error: %d ENOBUFS %@",err,errString);
			break;
		case ENOTSOCK:
			NSLog(@"Error: %d ENOTSOCK %@",err,errString);
			break;
		case EOPNOTSUPP:
			NSLog(@"Error: %d EOPNOTSUPP %@",err,errString);
			break;
		case EPROTOTYPE:
			NSLog(@"Error: %d EPROTOTYPE %@",err,errString);
			break;
		case ETIMEDOUT:
			NSLog(@"Error: %d ETIMEDOUT %@",err,errString);
			break;
		case EIO:
			NSLog(@"Error: %d EIO %@",err,errString);
			break;
		case ELOOP:
			NSLog(@"Error: %d ELOOP %@",err,errString);
			break;
		case ENAMETOOLONG:
			NSLog(@"Error: %d ENAMETOOLONG %@",err,errString);
			break;
		case ENOENT:
			NSLog(@"Error: %d ENOENT %@",err,errString);
			break;
		case ENOTDIR:
			NSLog(@"Error: %d ENOTDIR %@",err,errString);
			break;
		case ENOTCONN:
			NSLog(@"Error: %d ENOTCONN %@",err,errString);
			break;
		case EAGAIN:
			NSLog(@"Error: %d EAGAIN %@",err,errString);
			break;
		default:
			NSLog(@"Error: %d %@",err,errString);
			break;
	}
}


- (void) reportStatus: (NSString *)str
{
    if(reportDelegate)
    {
        [reportDelegate reportStatus:str];
    }
    else
    {
        // NSLog(@"%@: %@",[self description],str);
    }
}

- (void) updateName
{
    NSString	*proto = nil;
    NSString	*host = nil;
    char		tmpAddress[256];
    int has_host = 0;
    int has_device = 0;
    
    NSString *xconnectedRemoteAddress;
    //int      xconnectedRemoteAddressType;
    int      xconnectedRemotePort=0;
    
    NSString *xconnectedLocalAddress;
    //int      xconnectedLocalAddressType;
    int      xconnectedLocalPort=0;
    
    struct sockaddr_in	sa_local_in4;
    struct sockaddr_in6	sa_local_in6;
    struct sockaddr_in	sa_remote_in4;
    struct sockaddr_in6	sa_remote_in6;
    struct sockaddr	sa_local;
    struct sockaddr	sa_remote;
    socklen_t len;
    
    memset(&sa_local,0x00,sizeof(sa_local));
    memset(&sa_local_in4,0x00,sizeof(sa_local_in4));
    memset(&sa_local_in6,0x00,sizeof(sa_local_in6));
    
    memset(&sa_remote,0x00,sizeof(sa_remote));
    memset(&sa_remote_in4,0x00,sizeof(sa_remote_in4));
    memset(&sa_remote_in6,0x00,sizeof(sa_remote_in6));
    
    len = sizeof(sa_local);
    getsockname(_sock, &sa_local, &len);
    switch(sa_local.sa_family)
    {
        case AF_INET:
            len = sizeof(sa_local_in4);
            getsockname(_sock, (struct sockaddr *)&sa_local_in4, &len);
            inet_ntop(AF_INET, &sa_local_in4.sin_addr, tmpAddress, 256);
            xconnectedLocalAddress = [[NSString alloc]initWithCString:tmpAddress encoding:NSASCIIStringEncoding];
            //xconnectedLocalAddressType=4;
            xconnectedLocalPort = ntohs(sa_local_in4.sin_port);
            break;
        case AF_INET6:
            len = sizeof(sa_local_in6);
            getsockname(_sock,(struct sockaddr *) &sa_local_in6, &len);
            inet_ntop(AF_INET6, &sa_local_in6.sin6_addr, tmpAddress, 256);
            xconnectedLocalAddress = [[NSString alloc]initWithCString:tmpAddress encoding:NSASCIIStringEncoding];
            //xconnectedLocalAddressType=6;
            xconnectedLocalPort = ntohs(sa_local_in6.sin6_port);
            break;
    }
    
    len = sizeof(sa_remote);
    getpeername(_sock, &sa_remote, &len);
    switch(sa_remote.sa_family)
    {
        case AF_INET:
            len = sizeof(sa_remote_in4);
            getpeername(_sock, (struct sockaddr *)&sa_remote_in4, &len);
            inet_ntop(AF_INET, &sa_remote_in4.sin_addr, tmpAddress, 256);
            xconnectedRemoteAddress = [[NSString alloc]initWithCString:tmpAddress encoding:NSASCIIStringEncoding];
            //xconnectedRemoteAddressType=4;
            xconnectedRemotePort = ntohs(sa_remote_in4.sin_port);
            break;
        case AF_INET6:
            len = sizeof(sa_remote_in6);
            getpeername(_sock, (struct sockaddr *)&sa_remote_in6, &len);
            inet_ntop(AF_INET6, &sa_remote_in6.sin6_addr, tmpAddress, 256);
            xconnectedRemoteAddress = [[NSString alloc]initWithCString:tmpAddress encoding:NSASCIIStringEncoding];
            //xconnectedRemoteAddressType=6;
            xconnectedRemotePort =ntohs(sa_remote_in6.sin6_port);
            break;
    }
    
    proto = [UMSocket socketTypeDescription:type];
    switch(type)
    {
        case UMSOCKET_TYPE_NONE:
            has_host = 0;
            has_device = 0;
            break;
        case UMSOCKET_TYPE_TCP6ONLY:
        case UMSOCKET_TYPE_TCP4ONLY:
        case UMSOCKET_TYPE_TCP:
            has_host = 1;
            has_device = 0;
            break;
        case UMSOCKET_TYPE_UDP4ONLY:
        case UMSOCKET_TYPE_UDP6ONLY:
        case UMSOCKET_TYPE_UDP:
            has_host = 1;
            has_device = 0;
            break;
        case UMSOCKET_TYPE_SCTP4ONLY:
        case UMSOCKET_TYPE_SCTP6ONLY:
        case UMSOCKET_TYPE_SCTP:
            has_host = 1;
            has_device = 0;
            break;
        case UMSOCKET_TYPE_DNSTUN:
            has_host = 0;
            has_device = 0;
            break;
        case  UMSOCKET_TYPE_UNIX:
            has_host = 0;
            has_device = 1;
            break;
        case UMSOCKET_TYPE_MEMORY:
            has_host = 0;
            has_device = 0;
            break;
        case UMSOCKET_TYPE_SERIAL:
            has_host = 0;
            has_device = 1;
            break;
        default:
            has_host = 1;
            has_device = 0;
            break;
    }
    
    xconnectedLocalAddress = [UMSocket unifyIP:xconnectedLocalAddress];
    xconnectedRemoteAddress = [UMSocket unifyIP:xconnectedRemoteAddress];
    if(has_host)
    {
        switch(direction)
        {
                
            case UMSOCKET_DIRECTION_OUTBOUND:
                host = [[NSString alloc] initWithFormat:@"%@:%d-->%@:%d",
                        EMPTYIPFORNIL(xconnectedLocalAddress),xconnectedLocalPort,
                        EMPTYIPFORNIL(xconnectedRemoteAddress),xconnectedRemotePort];
                break;
                
            case UMSOCKET_DIRECTION_INBOUND:
                host = [[NSString alloc] initWithFormat:@"%@:%d<--%@:%d",
                        EMPTYIPFORNIL(xconnectedLocalAddress),  xconnectedLocalPort,
                        EMPTYIPFORNIL(xconnectedRemoteAddress), xconnectedRemotePort];
                break;
            case UMSOCKET_DIRECTION_PEER:
                host = [[NSString alloc] initWithFormat:@"%@:%d<->%@:%d",
                        EMPTYIPFORNIL(xconnectedLocalAddress), xconnectedLocalPort,
                        EMPTYIPFORNIL(xconnectedRemoteAddress),xconnectedRemotePort];
                break;
            case UMSOCKET_DIRECTION_UNSPECIFIED:
                host = [[NSString alloc] initWithFormat:@"%@:%d<?>%@:%d",
                        EMPTYIPFORNIL(xconnectedLocalAddress), xconnectedLocalPort,
                        EMPTYIPFORNIL(xconnectedRemoteAddress), xconnectedRemotePort];
                break;
            default:
                host = [[NSString alloc] initWithFormat:@"<unknown type>"];
                break;
        }
    }
    if(has_device)
    {
        name = [[NSString alloc] initWithFormat: @"%@://%@%@",proto,host,device];
    }
    else
    {
        name = [[NSString alloc] initWithFormat: @"%@://%@/",proto,host];
    }
    self.connectedLocalAddress = xconnectedLocalAddress;
    self.connectedRemoteAddress = xconnectedRemoteAddress;
    self.connectedRemotePort = xconnectedRemotePort;
    self.connectedLocalPort = xconnectedLocalPort;
    host = nil;
}

- (void) setEvent: (int) event
{
	NSLog(@"%@: poll event %d",[self description],event);
	lastPollEvent = event;
}

- (UMSocketError) receiveToBufferWithBufferLimit: (int) max
{
	return [self receiveToBufferWithBufferLimit: max read:NULL];
} 

- (UMSocketError) receiveToBufferWithBufferLimit: (int) max read:(ssize_t *)read_count
{
    ssize_t wantReadBytes;
    ssize_t actualReadBytes;
    ssize_t remainingBytes;
    ssize_t totalReadBytes = 0;
    int eno = 0;
    UMSocketError e=UMSocketError_no_error;
    
    unsigned char chunk[UMBLOCK_READ_SIZE];
    
    [self switchToNonBlocking];
    
    remainingBytes = max - [receiveBuffer length];
    while (remainingBytes > 0)
    {
        if(remainingBytes < UMBLOCK_READ_SIZE)
        {
            wantReadBytes = remainingBytes;
        }
        else
        {
            wantReadBytes = UMBLOCK_READ_SIZE;
        }

        actualReadBytes = [cryptoStream readBytes:chunk
                                       length:wantReadBytes
                                    errorCode:&eno];
        
        if(actualReadBytes == 0) /* SIGHUP */
        {
            if(totalReadBytes==0)
            {
                e = UMSocketError_connection_reset;
            }
            else
            {
                e = UMSocketError_has_data_and_hup;

            }
            break;
        }
        else if(actualReadBytes < 0)	/* we got an error */
        {
            /* if we get EAGAIN it means there's nothing more to be read so we jump out of the while */
            if((eno == EWOULDBLOCK) || (eno == EAGAIN))
            {
                break;
            }
            /* anyhting else means more fatal error */
            if(read_count)
            {
            	*read_count = actualReadBytes;
            }
            return [UMSocket umerrFromErrno:eno];
        }
        else
        {
            [receiveBuffer appendBytes:chunk length:actualReadBytes];
            remainingBytes -= actualReadBytes;
            totalReadBytes += actualReadBytes;
            if(actualReadBytes == wantReadBytes)	/* we have read a full chunk. but there might be more. lets continue */
            {
                continue;
            }
        }
    }
    if(read_count)
    {
		*read_count = totalReadBytes;
    }
    return e;
}

- (UMSocketError) receiveLineTo:(NSData **)toData
{
    unsigned char lf[] = {10};
    NSData *eol = [NSData dataWithBytes:lf length:1];
    NSData *d = NULL;
    UMSocketError err = [self receiveLineTo:&d eol:eol];
    if(d)
    {
        const uint8_t *bytes = d.bytes;
        NSUInteger len = d.length;
        if(bytes[len-1]== 13)
        {
            /* line terminating with CRLF and we have eaten the LF already */
            *toData = [NSData dataWithBytes:bytes length:(len-1)];
        }
        else
        {
            /* line terminating with pure LF */
            *toData = d;
        }
    }
    return err;
}

- (UMSocketError) receiveLineToLF:(NSData **)toData
{
    unsigned char lf[] = {10};
    NSData *eol = [NSData dataWithBytes:lf length:1];
    return [self receiveLineTo:toData eol:eol];
}

- (UMSocketError) receiveLineToCR:(NSData **)toData
{
    unsigned char cr[] = {13};
    NSData *eol = [NSData dataWithBytes:cr length:1];
    return [self receiveLineTo:toData eol:eol];
}

- (UMSocketError) receiveLineToCRLF:(NSData **)toData
{
    unsigned char crlf[] = {13,10};
    NSData *eol = [NSData dataWithBytes:crlf length:2];
    UMSocketError err = [self receiveLineTo:toData eol:eol];
    return err;
}


- (UMSocketError) receiveLineTo:(NSData **)toData eol:(NSData *)eol
{
    NSRange pos;
    unsigned char chunk[UMBLOCK_READ_SIZE];
    ssize_t actualReadBytes;
    UMSocketError sErr;
    [self switchToNonBlocking];
    int eno = 0;
    
    *toData = nil;

    pos = [receiveBuffer rangeOfData_dd:eol startingFrom:receivebufpos];
    if (pos.location == NSNotFound)
    {
        actualReadBytes = [cryptoStream readBytes:chunk
                                       length:sizeof(chunk)
                                    errorCode:&eno];
        if (actualReadBytes <= 0)
        {
            if (eno == EINTR || eno == EAGAIN || eno == EWOULDBLOCK )
            {
                usleep(10000);
                return UMSocketError_try_again;
            }
            else
            {
                NSLog(@"we have socket err %d set error %d", errno, eno);
                sErr = [UMSocket umerrFromErrno:eno];
                return sErr;
            }
        }
        
        [receiveBuffer appendBytes:chunk length:actualReadBytes];
        pos = [receiveBuffer rangeOfData_dd:eol startingFrom:receivebufpos];
        if (pos.location == NSNotFound)
        {
            NSLog(@"we have no eol");
            return UMSocketError_no_error;
        }
    }
    
    NSMutableData *tmp = [[receiveBuffer subdataWithRange:NSMakeRange(receivebufpos, pos.location - receivebufpos)]mutableCopy];
    if([tmp length]==0)
    {
        *toData = NULL;
        return UMSocketError_no_error;
    }
    *toData = tmp;
    [self deleteFromReceiveBuffer:pos.location+pos.length];
    receivebufpos = 0;
    return UMSocketError_no_error;
}


- (UMSocketError) receive:(long)bytes to:(NSData **)returningData
{
    long i;
    ssize_t actualReadBytes;
    unsigned char chunk[UMBLOCK_READ_SIZE];
    UMSocketError sErr;
    
    [self switchToNonBlocking];
    
    *returningData = nil;
   // NSLog(@"[UMsocket receive:to:] %@", [self fullDescription]);
    
    
    /* skip heading spaces */
    if(receivebufpos > 0)
    {
        NSLog(@"receivebufpos was %ld, remove heading",(long)receivebufpos);
        /* remove heading */
        [receiveBuffer replaceBytesInRange:NSMakeRange(0, receivebufpos) withBytes:nil length:0];
        receivebufpos = 0;
    }

    i = receivebufpos;
    const unsigned char *c = receiveBuffer.bytes;
    NSUInteger len = receiveBuffer.length;
    while(i<len)
    {
        if (!isspace(c[0]))
        {
            break;
        }
        i++;
    }
    [self deleteFromReceiveBuffer:i];

    size_t start = receivebufpos;
    size_t end = bytes + receivebufpos;
    int eno = 0;
    while ([receiveBuffer length] < end)
    {
        size_t remainingSize =  end - start - [receiveBuffer length];
        if(remainingSize > sizeof(chunk))
        {
            actualReadBytes = [cryptoStream readBytes:chunk
                                           length:sizeof(chunk)
                                        errorCode:&eno];
        }
        else
        {
            actualReadBytes = [cryptoStream readBytes:chunk
                                           length:remainingSize
                                        errorCode:&eno];
        }
        eno = errno;
        if (actualReadBytes <= 0)
        {
            if (eno == EINTR || eno == EAGAIN || eno == EWOULDBLOCK)
            {
                usleep(10000);
                NSLog(@"[UMsocket receive:to:] timeout");
                return UMSocketError_try_again;
            }
            else
            {
                sErr = [UMSocket umerrFromErrno:eno];
                NSLog(@"[UMsocket receive:to:] error: %@", [UMSocket getSocketErrorString:sErr]);
                return sErr;
            }
        }
        else
        {
            [receiveBuffer appendBytes:&chunk[0] length:actualReadBytes];
        }
    }
    
    NSData *resultData = [receiveBuffer subdataWithRange:NSMakeRange(receivebufpos, bytes)];
    *returningData  = resultData;
    
    [receiveBuffer replaceBytesInRange:NSMakeRange(0, end) withBytes:nil length:0];
    receivebufpos = 0;
    return UMSocketError_no_error;
}

-(void)sendNow
{
}

+ (UMSocketError) umerrFromErrno:(int)e
{
	switch(e)
    {
        case EACCES:
            return UMSocketError_insufficient_privileges;
        case EADDRINUSE:
            return UMSocketError_address_already_in_use;
        case EADDRNOTAVAIL:
            return UMSocketError_address_not_available;
        case EAFNOSUPPORT:
            return UMSocketError_address_not_valid_for_socket_family;
        case EBADF:
            return UMSocketError_invalid_file_descriptor;
        case EFAULT:
            return UMSocketError_pointer_not_in_userspace;
        case EINVAL:
            return UMSocketError_already_bound;
        case ENOTSOCK:
            return UMSocketError_not_a_socket;
        case EOPNOTSUPP:
            return UMSocketError_not_supported_operation;
        case EIO:
            return UMSocketError_io_error;
        case EISDIR:
            return UMSocketError_empty_path_name;
        case ELOOP:
            return UMSocketError_loop;
        case ENAMETOOLONG:
            return UMSocketError_name_too_long;
        case ENOENT:
            return UMSocketError_not_existing;
        case EROFS:
            return UMSocketError_readonly;
        case EINTR:
            return UMSocketError_execution_interrupted;
        case EDESTADDRREQ:
            return UMSocketError_not_bound;
        case EAGAIN:
            return UMSocketError_try_again;
        case ETIMEDOUT:
            return UMSocketError_timed_out;
        case ECONNREFUSED:
            return UMSocketError_connection_refused;
        case ENOBUFS:
            return UMSocketError_no_buffers;
        case ENOMEM:
            return UMSocketError_no_memory;
        case ENXIO:
            return UMSocketError_nonexistent_device;
        case ECONNRESET:
            return UMSocketError_connection_reset;
        case EDQUOT:
            return UMSocketError_user_quota_exhausted;
        case EFBIG:
            return UMSocketError_efbig;
        case ENETDOWN:
            return UMSocketError_network_down;
        case ENETUNREACH:
            return UMSocketError_network_unreachable;
        case ENOSPC:
            return UMSocketError_no_space_left;
        case EPIPE:
            return UMSocketError_pipe_error;
        case ESRCH:
            return UMSocketError_no_such_process;
        case EHOSTDOWN:
            return UMSocketError_host_down;
        default:
            
            NSLog(@"Unknown errno code %d",e);
            break;
    }
	return UMSocketError_not_known;
}

+ (NSString *) getSocketErrorString:(UMSocketError)e
{
	switch(e)
    {
        case UMSocketError_has_data_and_hup:
            return @"has_data_and_hup";
        case UMSocketError_has_data:
            return @"has_data";
        case UMSocketError_no_error:
            return @"no_error";
        case UMSocketError_generic_error:
            return @"generic_error";
        case UMSocketError_already_bound:
            return @"already_bound";
        case UMSocketError_already_listening:
            return @"already_listening";
        case UMSocketError_insufficient_privileges:
            return @"insufficient_privileges";
        case UMSocketError_invalid_file_descriptor:
            return @"invalid_file_descriptor";
        case UMSocketError_not_bound:
            return @"not_bound";
        case UMSocketError_already_connected:
            return @"already_connected";
        case UMSocketError_not_a_socket:
            return @"not_a_socket";
        case UMSocketError_not_supported_operation:
            return @"not_supported_operation";
        case UMSocketError_generic_listen_error:
            return @"generic_listen_error";
        case UMSocketError_generic_close_error:
            return @"generic_close_error";
        case UMSocketError_execution_interrupted:
            return @"execution_interrupted";
        case UMSocketError_io_error:
            return @"io_error";
        case UMSocketError_sctp_bindx_failed_for_all:
            return @"sctp_bindx_failed_for_all";
        case UMSocketError_address_already_in_use:
            return @"address_already_in_use";
        case UMSocketError_address_not_available:
            return @"address_not_available";
        case UMSocketError_address_not_valid_for_socket_family:
            return @"address_not_valid_for_socket_family";
        case UMSocketError_socket_is_null_pointer:
            return @"socket_is_null_pointer";
        case UMSocketError_pointer_not_in_userspace:
            return @"pointer_not_in_userspace";
        case UMSocketError_empty_path_name:
            return @"empty_path_name";
        case UMSocketError_loop:
            return @"loop";
        case UMSocketError_name_too_long:
            return @"name_too_long";
        case UMSocketError_not_existing:
            return @"not_existing";
        case UMSocketError_not_a_directory:
            return @"not_a_directory";
        case UMSocketError_readonly:
            return @"readonly";
        case UMSocketError_generic_bind_error:
            return @"generic_bind_error";
        case  UMSocketError_try_again:
            return @"timeout";
        case  UMSocketError_timed_out:
            return @"connection attempt timed out";
        case  UMSocketError_connection_refused:
            return @"connection refused";
        case  UMSocketError_connection_reset:
            return @"connection reset";
        case UMSocketError_no_buffers:
            return @"no buffers available";
        case UMSocketError_no_memory:
            return @"no memory available";
        case UMSocketError_nonexistent_device:
            return @"nonexistent device";
        case UMSocketError_user_quota_exhausted:
            return @"User quota exhausted";
        case UMSocketError_efbig:
            return @"too big";
        case UMSocketError_network_down:
            return @"Network down";
        case UMSocketError_network_unreachable:
            return @"Network unreachable";
        case UMSocketError_no_space_left:
            return @"no space left on device";
        case UMSocketError_pipe_error:
            return @"pipe error";
        case UMSocketError_host_down:
            return @"host down";
        default:
            return [NSString stringWithFormat:@"Unknown error code %d",e];
    }
}

#ifdef SCTP_IN_USERSPACE
int receive_usrsctp_cb(struct usocket *sock, union sctp_sockstore addr, void *data,
                       size_t datalen, struct sctp_rcvinfo rxinfo, int flags, void *ulp_info)
{
    
}

int send_usrsctp_cb(struct usocket *sock, uint32_t sb_free)
{
    
}
#endif

+(NSString *)unifyIP:(NSString *)addr
{
    if(addr == NULL)
    {
        return NULL;
    }
    else if([addr isEqualToString:@"0.0.0.0"])
    {
        return @"ipv4:0.0.0.0";
    }
    else if([addr length]==0)
    {
        return @"ipv6:[::]";
    }

    else if(([addr isEqualToString:@"::1"]) || ([addr isEqualToString:@"ipv6[::1]"]))
    {
        return @"ipv6:localhost";
    }

    else if(
            [addr isEqualToString:@"127.0.0.1"] ||
            [addr isEqualToString:@"::ffff:127.0.0.1"] ||
            [addr isEqualToString:@"ipv4:127.0.0.1"] ||
            [addr isEqualToString:@"ipv6:[::ffff:127.0.0.1]"])
    {
        return @"ipv4:localhost";
    }

    else if ([addr hasPrefix:@"ipv4:"])
    {
        addr = [addr substringFromIndex:5];
        NSArray *a = [addr componentsSeparatedByString:@"."];
        if([a count]==4)
        {
            int a1 = [[a objectAtIndex:0] intValue];
            int a2 = [[a objectAtIndex:1] intValue];
            int a3 = [[a objectAtIndex:2] intValue];
            int a4 = [[a objectAtIndex:3] intValue];
            a1 = a1 % 256;
            a2 = a2 % 256;
            a3 = a3 % 256;
            a4 = a4 % 256;
            return [NSString stringWithFormat:@"ipv4:%d.%d.%d.%d",a1,a2,a3,a4];
        }
    }
    else if ([addr hasPrefix:@"ipv6:"])
    {
        addr = [addr substringFromIndex:5];
        if([addr length]>7)
        {
            if([[addr substringToIndex:7]isEqualToString:@"::ffff:"])
            {
                return [NSString stringWithFormat:@"ipv4:%@",[addr substringFromIndex:7]];
            }
        }
        return [NSString stringWithFormat:@"ipv6:[%@]", addr];
    }

    NSArray *a = [addr componentsSeparatedByString:@"."];
    if([a count]==4)
    {
        int a1 = [[a objectAtIndex:0] intValue];
        int a2 = [[a objectAtIndex:1] intValue];
        int a3 = [[a objectAtIndex:2] intValue];
        int a4 = [[a objectAtIndex:3] intValue];
        a1 = a1 % 256;
        a2 = a2 % 256;
        a3 = a3 % 256;
        a4 = a4 % 256;
        return [NSString stringWithFormat:@"ipv4:%d.%d.%d.%d",a1,a2,a3,a4];
    }
    else
    {
        if([addr length]>7)
        {
            if([[addr substringToIndex:7]isEqualToString:@"::ffff:"])
            {
                return [NSString stringWithFormat:@"ipv4:%@",[addr substringFromIndex:7]];
            }
        }
        return [NSString stringWithFormat:@"ipv6:[%@]", addr];
    }
    return [NSString stringWithFormat:@"ipv4:%@",addr];
}

+(NSString *)deunifyIp:(NSString *)addr type:(int *)t
{
    if([addr isEqualToString:@"ipv6:[::]"])
    {
        *t = 6;
        return @"::";
    }
    if([addr isEqualToString:@"ipv6:localhost"])
    {
        *t = 6;
        return @"localhost";
    }
    if([addr isEqualToString:@"ipv4:localhost"])
    {
        *t = 4;
        return @"localhost";
    }

    NSString *addrtype =   [addr substringToIndex:4];
    if([addrtype isEqualToString:@"ipv4"])
    {
        *t = 4;
        NSInteger start = 5;
        NSInteger len = [addr length] - start;
        if(len < 1)
        {
            *t = 0;
            return @"";
        }
        return [addr substringWithRange:NSMakeRange(start,len)];
    }
    
    else if([addrtype isEqualToString:@"ipv6"])  /* format: ipv6:[xxx:xxx:xxx...:xxxx] */
    {
        *t = 6;
        NSInteger start = 5;
        NSInteger len = [addr length] -1 - start;
        if(len < 1)
        {
            *t = 0;
            return NULL;
        }
        return [addr substringWithRange:NSMakeRange(start,len)];
    }
    else
    {
        *t = 0;
        return @"";
    }
}


#define RXBUFSIZE   (32*1024)
- (UMSocketError) receiveData:(NSData **)toData
                  fromAddress:(NSString **)address
                     fromPort:(int *)port
{
    ssize_t rxsize;
    char rxbuf[RXBUFSIZE];
    char hbuf[NI_MAXHOST];
    char sbuf[NI_MAXSERV];

    size_t len = sizeof(rxbuf);
    struct sockaddr_storage src_addr;
    socklen_t addrlen = sizeof (src_addr);
    int flags = MSG_DONTWAIT;
    
    *toData = NULL;
    *address = NULL;
    *port = 0;
    memset(&src_addr,0,addrlen);

    rxsize = recvfrom(_sock, rxbuf,len,flags, (struct sockaddr *)&src_addr, &addrlen);

    if(rxsize > 0)
    {
        uint16_t p;
        *toData = [NSData dataWithBytes:rxbuf length:rxsize];
        sa_family_t family = src_addr.ss_family;
        if(family == AF_INET6)
        {
            p = ((struct sockaddr_in6 *)&src_addr)->sin6_port;
        }
        else
        {
            p = ((struct sockaddr_in *)&src_addr)->sin_port;
        }

        if (getnameinfo((struct sockaddr *)&src_addr,
                        addrlen,
                        hbuf,
                        sizeof(hbuf),
                        sbuf,
                        sizeof(sbuf),
                        NI_NUMERICHOST | NI_NUMERICSERV))
        {
            *address = @"";
        }
        else
        {
            if(family == AF_INET6)
            {
                if(strncmp(hbuf,"::ffff:",7)==0)
                {
                    *address = [NSString stringWithFormat:@"ipv4:%@",@(&hbuf[7])];
                }
                else
                {
                    *address = [NSString stringWithFormat:@"ipv6:[%@]",@(hbuf)];
                }
            }
            else
            {
                *address = [NSString stringWithFormat:@"ipv4:[%@]",@(hbuf)];
                p = ((struct sockaddr_in *)&src_addr)->sin_port;
            }
        }
        *port = (int)ntohs(p);
        return UMSocketError_no_error;
    }
    return UMSocketError_no_data;
}

- (UMSocketError) sendData:(NSData *)data
                 toAddress:(NSString *)unifiedAddr
                    toPort:(int)port
{
    
    int addrtype = 0;
    ssize_t sentDataSize = 0;
    int flags = MSG_DONTWAIT;

    NSString *addr = [UMSocket deunifyIp:unifiedAddr type:&addrtype];

    if(_family==AF_INET)
    {
        struct sockaddr_in	sa;
        
        memset(&sa,0x00,sizeof(sa));
        sa.sin_family		= _family;
#ifdef	HAS_SOCKADDR_LEN
        sa.sin_len			= sizeof(struct sockaddr_in);
#endif
        sa.sin_port             = htons(port);
        inet_pton(_family, addr.UTF8String, &sa.sin_addr);
        int flags=0;
        sentDataSize = sendto(_sock,
                              [data bytes],
                              (size_t)[data length],
                              flags,
                              (struct sockaddr *)&sa,
                              (socklen_t) sizeof(struct sockaddr_in));
    }
    else if(_family==AF_INET6)
    {

        struct sockaddr_in6	sa6;

        memset(&sa6,0x00,sizeof(sa6));
        sa6.sin6_family			= _family;
#ifdef	HAS_SOCKADDR_LEN
        sa6.sin6_len        = sizeof(struct sockaddr_in6);
#endif
        sa6.sin6_port       = htons(requestedRemotePort);
        inet_pton(_family, addr.UTF8String, &sa6.sin6_addr);

        sentDataSize = sendto(_sock, [data bytes],
                              (size_t)[data length],
                              flags,
                              (struct sockaddr *)&sa6,
                              (socklen_t) sizeof(struct sockaddr_in6));
    }
    
    if(sentDataSize == [data length])
    {
        return UMSocketError_no_error;
    }
    int eno = errno;
    return [UMSocket umerrFromErrno:eno];
}

- (void)startTLS
{
    [UMSocket initSSL];
    
    /*
     * make sure the socket is non-blocking while we do SSL_connect
     */
    [self switchToNonBlocking];

    ssl = (void *)SSL_new(global_server_ssl_context);
    ERR_clear_error();
    if (serverSideCertFilename != NULL)
    {
        SSL_use_certificate_file((SSL *)ssl, serverSideCertFilename.UTF8String,SSL_FILETYPE_PEM);
        SSL_use_PrivateKey_file((SSL *)ssl, serverSideKeyFilename.UTF8String,SSL_FILETYPE_PEM);
        if (SSL_check_private_key((SSL *)ssl) != 1)
        {
            NSString *msg = [NSString stringWithFormat:@"startTLS: private key isn't consistent with the certificate from file %@ (or failed reading the file)",serverSideCertFilename];
            @throw([NSException exceptionWithName:@"INVALID_SSL_KEYS"
                                           reason:NULL
                                         userInfo:@{
                                                    @"sysmsg" : msg,
                                                    @"func": @(__func__),
                                                    @"err": @(1)
                                                    }]);
            
            return;
        }
    }
    
    /* SSL_set_fd can fail, so check it */
    if (0==SSL_set_fd((SSL *)ssl, _sock))
    {
        /* SSL_set_fd failed, log error */
        NSLog(@"SSL: OpenSSL: %.256s", ERR_error_string(ERR_get_error(), NULL));
        return;
    }

    BIO_set_nbio(SSL_get_rbio((SSL *)ssl), 1);
    BIO_set_nbio(SSL_get_wbio((SSL *)ssl), 1);

    if(direction == UMSOCKET_DIRECTION_INBOUND)
    {
        SSL_set_accept_state((SSL *)ssl);
    }
    else if(direction == UMSOCKET_DIRECTION_OUTBOUND)
    {
        SSL_set_connect_state((SSL *)ssl);
    }
    
    int i = SSL_do_handshake((SSL *)ssl);
    if(i<0)
    {
        int ssl_error = SSL_get_error((SSL *)ssl,i);
        if(ssl_error != SSL_ERROR_WANT_READ)
        {
            NSLog(@"ssl_error=%d during SSL_do_handshake",ssl_error);
        }
    }
    sslActive = YES;
    cryptoStream.enable=sslActive;
}

- (int) fileDescriptor
{
    return _sock;
}

- (void *)ssl
{
    return ssl;
}



+ (void)initSSL
{
    if(global_server_ssl_context == NULL)
    {
        SSL_library_init();
        SSLeay_add_ssl_algorithms();
        SSL_load_error_strings();
        global_server_ssl_context = SSL_CTX_new(TLSv1_2_server_method());
        global_client_ssl_context = SSL_CTX_new(TLSv1_2_client_method());
        
        SSL_CTX_set_mode(global_client_ssl_context,
                             SSL_MODE_ENABLE_PARTIAL_WRITE | SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER);
        SSL_CTX_set_mode(global_server_ssl_context,
                         SSL_MODE_ENABLE_PARTIAL_WRITE | SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER);
    
        if (!SSL_CTX_set_default_verify_paths(global_server_ssl_context))
        {
            @throw ([NSException exceptionWithName:@"PANIC"
                                            reason:@"can not set default path for SSL server. SSL_CTX_set_default_verify_paths() fails"
                                          userInfo:@{@"backtrace": UMBacktrace(NULL,0)}]);

        }
        
        int maxlocks = CRYPTO_num_locks();
            
        ssl_static_locks = (umlock_c_pointer *)malloc(sizeof(umlock_c_pointer) * maxlocks);
        for (int c = 0; c < maxlocks; c++)
        {
            UMLock *lck = [[UMLock alloc]initNonReentrantWithFile:__FILE__ line:__LINE__ function:"ssl"];
            ssl_static_locks[c] = (__bridge_retained umlock_c_pointer)lck;
        }
        CRYPTO_set_locking_callback(openssl_locking_function);
        CRYPTO_THREADID_set_callback(crypto_threadid_callback);
        CRYPTO_set_dynlock_create_callback(dyn_create_function);
        CRYPTO_set_dynlock_lock_callback(dyn_lock_function);
        CRYPTO_set_dynlock_destroy_callback(dyn_destroy_function);
    }
}

@end


static void crypto_threadid_callback(CRYPTO_THREADID *ctid)
{
    void *p = (void *)pthread_self();
    CRYPTO_THREADID_set_pointer(ctid, p);
}

static void openssl_locking_function(int mode, int n, const char *file, int line)
{
    UMLock *lck = (__bridge UMLock *)ssl_static_locks[n-1];
    if (mode & CRYPTO_LOCK)
    {
        [lck lockAtFile:file line:line function:"ssl"];
    }
    else
    {
        [lck unlockAtFile:file line:line function:"ssl"];
    }
}

static CRYPTO_dynlock_value *dyn_create_function(const char *file, int line)
{
    UMLock *lck = [[UMLock alloc]initNonReentrantWithFile:file line:line function:"ssl"];
    
    return (__bridge_retained void *)lck;
}

static void dyn_lock_function(int mode, struct CRYPTO_dynlock_value *l, const char *file, int line)
{
    UMLock *lck =  (__bridge UMLock *)l->umlock_ptr;
    
    if(mode & CRYPTO_LOCK)
    {
        [lck lockAtFile:file line:line function:"dyn_lock_function"];
    }
    if(mode & CRYPTO_UNLOCK)
    {
        [lck unlockAtFile:file line:line function:"dyn_lock_function"];
    }
}


static void dyn_destroy_function(struct CRYPTO_dynlock_value *l, const char *file, int line)
{
    UMLock *lck =  (__bridge_transfer UMLock *)l->umlock_ptr;
    l->umlock_ptr = NULL;
    lck = NULL;
}
