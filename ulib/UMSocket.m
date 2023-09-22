//
//  UMSocket.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMSocket.h>
#import <ulib/UMLogFeed.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>
#include <poll.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <netinet/tcp.h>
#include <netdb.h>

#import <ulib/UMMutex.h>
#import <ulib/NSData+ulib.h>
#import <ulib/UMAssert.h>
#import <ulib/UMFileTrackingMacros.h>
#import <ulib/NSString+ulib.h>
#import <ulib/UMSocketDefs.h>
#import <ulib/UMPacket.h>
#import <ulib/UMHistoryLog.h>
#import <ulib/UMUtil.h> /* for UMBacktrace */

#if defined(HAVE_OPENSSL)
#include <openssl/opensslconf.h>
#include <openssl/ssl.h>
#include <openssl/err.h>
#include <openssl/crypto.h>
#endif

#if OPENSSL_VERSION_NUMBER < 0x1010104fL
#error you need at least openssl 1.1.1d
#else
#define HAVE_TLS_METHOD 1
#endif

#import <ulib/ulib_config.h> /* for HAVE_SOCKADDR_IN etc */

typedef unsigned long (*CRYPTO_CALLBACK_PTR)(void);


#ifndef	IPPROTO_SCTP
#define	IPPROTO_SCTP	132
#endif			

#import <ulib/UMHost.h>

#define	UMBLOCK_READ_SIZE	1024
#define	EMPTYSTRINGFORNIL(a)	(a?a:@"")
#define	EMPTYIPFORNIL(a)		((a) ? (a) : @"0.0.0.0")


static SSL_CTX *global_client_ssl_context = NULL;
static SSL_CTX *global_server_ssl_context = NULL;
static SSL_CTX *global_generic_ssl_context = NULL;

typedef struct CRYPTO_dynlock_value
{
    void *ummutex_ptr;
} CRYPTO_dynlock_value;

struct usocket;
//typedef void *ummutex_c_pointer;
//static ummutex_c_pointer *ssl_static_locks;

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

- (void)initNetworkSocket
{
    _sock = -1;
    _hasSocket = NO;
    switch(_type)
    {
        case UMSOCKET_TYPE_TCP4ONLY:
            _socketDomain=AF_INET;
            _socketFamily=AF_INET;
            _socketType = SOCK_STREAM;
            _socketProto = 0;//IPPROTO_TCP;
            _sock = socket(_socketDomain, _socketType, _socketProto);
            TRACK_FILE_SOCKET(_sock,@"tcp");
            break;
        case UMSOCKET_TYPE_TCP6ONLY:
            _socketDomain=AF_INET6;
            _socketFamily=AF_INET6;
            _socketType = SOCK_STREAM;
            _socketProto = 0;//IPPROTO_TCP;
            _sock = socket(_socketFamily, _socketType, _socketProto);
            [self setIPv6Only];
            TRACK_FILE_SOCKET(_sock,@"tcp");
            break;
        case UMSOCKET_TYPE_TCP:
            _socketDomain=AF_INET6;
            _socketFamily=AF_INET6;
            _socketType = SOCK_STREAM;
            _socketProto = 0;//IPPROTO_TCP;
            _sock = socket(_socketFamily, SOCK_STREAM, _socketProto);
            TRACK_FILE_SOCKET(_sock,@"tcp");
            if(_sock < 0)
            {
                if(errno==EAFNOSUPPORT)
                {
                    _socketDomain=AF_INET;
                    _socketFamily=AF_INET;
                    _sock = socket(_socketFamily, _socketType, _socketProto);
                    TRACK_FILE_SOCKET(_sock,@"tcp");
                }
            }
            break;
        case UMSOCKET_TYPE_UDP4ONLY:
            _socketDomain=AF_INET;
            _socketFamily=AF_INET;
            _socketType = SOCK_DGRAM;
            _socketProto = 0;//IPPROTO_UDP;
            _sock = socket(_socketDomain, _socketType, _socketProto);
            TRACK_FILE_SOCKET(_sock,@"udp");
            break;
        case UMSOCKET_TYPE_UDP6ONLY:
            _socketDomain=AF_INET6;
            _socketFamily=AF_INET6;
            _socketType = SOCK_DGRAM;
            _socketProto = 0;//IPPROTO_UDP;
            _sock = socket(_socketDomain, _socketType, _socketProto);
            [self setIPv6Only];
            TRACK_FILE_SOCKET(_sock,@"udp");
            break;
        case UMSOCKET_TYPE_UDP:
            _socketDomain = AF_INET6;
            _socketFamily=AF_INET6;
            _socketType = SOCK_DGRAM;
            _socketProto = 0;//IPPROTO_UDP;
            _sock = socket(_socketDomain, _socketType, _socketProto);
            TRACK_FILE_SOCKET(_sock,@"udp");
            if(_sock < 0)
            {
                if(errno==EAFNOSUPPORT)
                {
                    _socketDomain = AF_INET;
                    _socketFamily=AF_INET;
                    _sock = socket(_socketFamily, _socketType, _socketProto);
                    TRACK_FILE_SOCKET(_sock,@"udp");
                }
            }
            break;
        case UMSOCKET_TYPE_SCTP4ONLY_SEQPACKET:
        case UMSOCKET_TYPE_SCTP6ONLY_SEQPACKET:
        case UMSOCKET_TYPE_SCTP_SEQPACKET:
        case UMSOCKET_TYPE_SCTP4ONLY_STREAM:
        case UMSOCKET_TYPE_SCTP6ONLY_STREAM:
        case UMSOCKET_TYPE_SCTP_STREAM:
        case UMSOCKET_TYPE_SCTP4ONLY_DGRAM:
        case UMSOCKET_TYPE_SCTP6ONLY_DGRAM:
        case UMSOCKET_TYPE_SCTP_DGRAM:
                /* we handle this in subclass UMSocketSCTP in ulibsctp */
            break;
        default:
            break;
    }
    if(_sock <0)
    {
        _hasSocket = NO;
    }
    else
    {
        _hasSocket = YES;
    }
}

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
    if(s==_sock)
    {
        return;
    }
    if((self.hasSocket) && (_sock >=0))
    {
        TRACK_FILE_CLOSE(_sock);
        close(_sock);
#if !defined(TARGET_OS_WATCH)
        [_netService stop];
        _netService=NULL;
#endif
    }
    _sock=s;
    if(_sock >=0)
    {
        self.hasSocket=YES;
    }
    else
    {
        self.hasSocket=NO;
    }
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
    case UMSOCKET_STATUS_LISTENING:
          return @"listening";
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
        case UMSOCKET_TYPE_SCTP_SEQPACKET:
            return @"sctp-seqpacket";
        case UMSOCKET_TYPE_SCTP4ONLY_SEQPACKET:
             return @"sctp4only-seqpacket";
        case UMSOCKET_TYPE_SCTP6ONLY_SEQPACKET:
             return @"sctp6only-seqpacket";
        case UMSOCKET_TYPE_SCTP_STREAM:
             return @"sctp-stream";
         case UMSOCKET_TYPE_SCTP4ONLY_STREAM:
             return @"sctp4only-stream";
        case UMSOCKET_TYPE_SCTP6ONLY_STREAM:
             return @"sctp6only-stream";
         case UMSOCKET_TYPE_SCTP_DGRAM:
              return @"sctp-dgram";
         case UMSOCKET_TYPE_SCTP4ONLY_DGRAM:
              return @"sctp4only-dgram";
         case UMSOCKET_TYPE_SCTP6ONLY_DGRAM:
              return @"sctp6only-dgram";
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
	if((_type==UMSOCKET_TYPE_TCP4ONLY) || (_type==UMSOCKET_TYPE_TCP6ONLY) || (_type==UMSOCKET_TYPE_TCP))
		return YES;
	return NO;
}

- (BOOL)	isUdpSocket
{
	if((_type==UMSOCKET_TYPE_UDP4ONLY) || (_type==UMSOCKET_TYPE_UDP6ONLY) || (_type==UMSOCKET_TYPE_UDP))
	   return YES;
	return NO;
}
		   
- (BOOL)	isSctpSocket
{
	if((_type==UMSOCKET_TYPE_SCTP4ONLY_SEQPACKET) || (_type==UMSOCKET_TYPE_SCTP6ONLY_SEQPACKET) || (_type==UMSOCKET_TYPE_SCTP_SEQPACKET) ||
          (_type==UMSOCKET_TYPE_USCTP4ONLY) || (_type==UMSOCKET_TYPE_USCTP6ONLY) || (_type==UMSOCKET_TYPE_USCTP) ||
          (_type==UMSOCKET_TYPE_SCTP4ONLY_STREAM) || (_type==UMSOCKET_TYPE_SCTP6ONLY_STREAM) || (_type==UMSOCKET_TYPE_SCTP_STREAM) ||
          (_type==UMSOCKET_TYPE_SCTP4ONLY_DGRAM) || (_type==UMSOCKET_TYPE_SCTP6ONLY_DGRAM) || (_type==UMSOCKET_TYPE_SCTP_DGRAM))
		return YES;
	return NO;
}

- (BOOL)	isUserspaceSocket
{
	if((_type==UMSOCKET_TYPE_USCTP4ONLY) || (_type==UMSOCKET_TYPE_USCTP6ONLY) || (_type==UMSOCKET_TYPE_USCTP))
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
    return [NSString stringWithFormat:@"%@ sock: %d",_name,_sock];
}

- (NSString *)fullDescription
{
    NSString *typeDesc = [UMSocket socketTypeDescription:_type];
    NSString *directionDesc = [UMSocket directionDescription:_direction];
    NSString *statusDesc = [UMSocket statusDescription:_status];
    NSString *localHostDesc = [_localHost description];
    NSString *remoteHostDesc = [_remoteHost description];
    
	[self updateName];

    NSString* l0 = [NSString localizedStringWithFormat:@"Name:                 %@", _name ? _name : @"not set"];
    NSString* l1 = [NSString localizedStringWithFormat:@"SocketType:           %@", typeDesc ? typeDesc : @"none available "];
    NSString* l2 = [NSString localizedStringWithFormat:@"Connection Direction: %@", directionDesc ? directionDesc : @"none available"];
    NSString* l3 = [NSString localizedStringWithFormat:@"Status:               %@", statusDesc ? statusDesc : @"none available"];
    NSString* l4 = [NSString localizedStringWithFormat:@"Local Host:           %@", localHostDesc ? localHostDesc : @"none available"];
    NSString* l5 = [NSString localizedStringWithFormat:@"Remote Host:          %@", remoteHostDesc ? remoteHostDesc : @"none available"];
    NSString* l6 = [NSString localizedStringWithFormat:@"Local Port:           %d", _connectedLocalPort];
    NSString* l7 = [NSString localizedStringWithFormat:@"Remote Port:          %d", _connectedRemotePort];
    NSString* l8;
    UMMUTEX_LOCK(_controlLock);
    l8 = [NSString localizedStringWithFormat:@"Socket:               %d", _sock];
    UMMUTEX_UNLOCK(_controlLock);
    return [NSString stringWithFormat:@"%@\n%@\n%@\n%@\n%@\n%@\n%@\n%@\n%@\n",l0,l1,l2,l3,l4,l5,l6,l7,l8];
}

- (void) dealloc
{
    if(_ssl)
    {
        SSL_smart_shutdown((SSL *)_ssl);
        SSL_free((SSL *)_ssl);
        _ssl = NULL;
    }
    /*
    if (peer_certificate != NULL)
    {
        X509_free((X509 *)peer_certificate);
        peer_certificate = NULL;
    }
*/
    if((_hasSocket) && (_sock >= 0))
    {
        fprintf(stderr,"deallocating a connection which has an open socket");
        TRACK_FILE_CLOSE(_sock);
        close(_sock);
        _sock = -1;
        _hasSocket = NO;
    }
}

- (UMSocket *) initWithType:(UMSocketType)t
{
    return [self initWithType:t name:@"unnamed"];
}

- (UMSocket *) initWithType:(UMSocketType)t name:(NSString *)name
{
    return [self initWithType:t name:name existingSocket:-1];
}

- (UMSocket *) initWithType:(UMSocketType)t name:(NSString *)name existingSocket:(int)sock
{
    self = [super init];
    if (self)
    {
        int reuse = 1;
        int linger_time = 1;
        _rx_crypto_enable = 0;
        _tx_crypto_enable = 0;
        _socketName = name;
        _cryptoStream = [[UMCrypto alloc] init];
        _controlLock = [[UMMutex alloc]initWithName:[NSString stringWithFormat:@"socket-control-lock (%@)",_socketName]];
        _dataLock = [[UMMutex alloc]initWithName:[NSString stringWithFormat:@"socket-data-lock (%@)",_socketName]];
        _type = t;
        _sock = sock;
        if(_sock < 0)
        {
            [self initNetworkSocket];
        }
        if(_sock >= 0)
        {
            /* success case */
            switch(_type)
            {
                case UMSOCKET_TYPE_TCP6ONLY:
                case UMSOCKET_TYPE_TCP4ONLY:
                case UMSOCKET_TYPE_TCP:
                    reuse=1;
                    linger_time=3;
                    break;
                case UMSOCKET_TYPE_UDP6ONLY:
                case UMSOCKET_TYPE_UDP4ONLY:
                case UMSOCKET_TYPE_UDP:
                    reuse=1;
                    linger_time=1;
                    break;
                case UMSOCKET_TYPE_SCTP4ONLY_SEQPACKET:
                case UMSOCKET_TYPE_SCTP6ONLY_SEQPACKET:
                case UMSOCKET_TYPE_SCTP_SEQPACKET:
                case UMSOCKET_TYPE_SCTP4ONLY_STREAM:
                case UMSOCKET_TYPE_SCTP6ONLY_STREAM:
                case UMSOCKET_TYPE_SCTP_STREAM:
                case UMSOCKET_TYPE_SCTP4ONLY_DGRAM:
                case UMSOCKET_TYPE_SCTP6ONLY_DGRAM:
                case UMSOCKET_TYPE_SCTP_DGRAM:
                    break;
                default:
                    break;
            }
        }
        else
        {
            /* error case */
            switch(_type)
            {
                case UMSOCKET_TYPE_TCP6ONLY:
                case UMSOCKET_TYPE_TCP4ONLY:
                case UMSOCKET_TYPE_TCP:
                    fprintf(stderr,"[UMSocket: init] socket(IPPROTO_TCP) returns %d errno = %d (%s)",_sock,errno,strerror(errno));
                    break;
                case UMSOCKET_TYPE_UDP6ONLY:
                case UMSOCKET_TYPE_UDP4ONLY:
                case UMSOCKET_TYPE_UDP:
                    fprintf(stderr,"[UMSocket: init] socket(IPPROTO_UDP) returns %d errno = %d (%s)",_sock,errno,strerror(errno));
                    break;
                case UMSOCKET_TYPE_SCTP4ONLY_SEQPACKET:
                case UMSOCKET_TYPE_SCTP6ONLY_SEQPACKET:
                case UMSOCKET_TYPE_SCTP_SEQPACKET:
                case UMSOCKET_TYPE_SCTP4ONLY_STREAM:
                case UMSOCKET_TYPE_SCTP6ONLY_STREAM:
                case UMSOCKET_TYPE_SCTP_STREAM:
                case UMSOCKET_TYPE_SCTP4ONLY_DGRAM:
                case UMSOCKET_TYPE_SCTP6ONLY_DGRAM:
                case UMSOCKET_TYPE_SCTP_DGRAM:
                    fprintf(stderr,"[UMSocket: init] socket(IPPROTO_SCTP) returns %d errno = %d (%s)",_sock,errno,strerror(errno));
                    break;
                default:
                    break;
            }
            return NULL;
        }
        if(_sock >=0)
        {
            self.hasSocket=YES;
            _cryptoStream.fileDescriptor = _sock;
        }
        _receiveBuffer = [[NSMutableData alloc] init];
        if(reuse)
        {
            /* see https://stackoverflow.com/questions/14388706/socket-options-so-reuseaddr-and-so-reuseport-how-do-they-differ-do-they-mean-t#14388707 */

            int err = setsockopt(_sock, SOL_SOCKET, SO_REUSEADDR, &reuse,sizeof(reuse));
            if(err != 0)
            {
                fprintf(stderr,"setsockopt(SO_REUSEADDR) failed %d (%s)\n",errno,strerror(errno));
            }
        }
        if(linger_time > 0)
        {
            struct linger xlinger;
            memset(&xlinger,0,sizeof(xlinger));
            xlinger.l_onoff = 1;
            xlinger.l_linger = linger_time;
            int err = setsockopt(_sock, SOL_SOCKET, SO_LINGER,  &xlinger,sizeof(xlinger));
            if(err !=0)
            {
                fprintf(stderr,"setsockopt(SOL_SOCKET,SO_LINGER,%d) failed %d %s\n",linger_time,errno,strerror(errno));
            }
        }
    }
    return self;
}

- (UMSocketError) bind
{
    UMMUTEX_LOCK(_controlLock);
    @try
    {
        int eno = 0;
        NSArray                 *localAddresses = NULL;
        NSMutableArray          *useableLocalAddresses;
        struct sockaddr_in	sa;
        struct sockaddr_in6	sa6;
        NSString    *ipAddr;
        char    addressString[256];

        [self reportStatus:@"bind()"];

        if (_isBound == YES)
        {
            [self reportStatus:@"- already bound"];
            return UMSocketError_already_bound;
        }
        if(_localHost == NULL)
        {
            _localHost               = [[UMHost alloc] initWithLocalhost];
        }
        localAddresses              = [_localHost addresses];
        useableLocalAddresses       = [[NSMutableArray alloc] init];

        memset(&sa,0x00,sizeof(sa));
        sa.sin_family			= AF_INET;
#ifdef	HAS_SOCKADDR_LEN
        sa.sin_len			= sizeof(struct sockaddr_in);
#endif
        sa.sin_port			= htons(_requestedLocalPort);
        sa.sin_addr.s_addr		= htonl(INADDR_ANY);
        memset(&sa6,0x00,sizeof(sa6));
        sa6.sin6_family			= AF_INET6;
#ifdef	HAS_SOCKADDR_LEN
        sa6.sin6_len			= sizeof(struct sockaddr_in);
#endif
        sa6.sin6_port			= htons(_requestedLocalPort);
        sa6.sin6_addr			= in6addr_any;

        switch(_type)
        {
#ifdef	SCTP_SUPPORTED
/* FIXME:  what about IPv4/IPv6 specifics? */
            case UMSOCKET_TYPE_SCTP_SEQPACKET:
            case UMSOCKET_TYPE_SCTP_STREAM:
            case UMSOCKET_TYPE_SCTP_DGRAM:
            case UMSOCKET_TYPE_SCTP4ONLY_SEQPACKET:
            case UMSOCKET_TYPE_SCTP4ONLY_STREAM:
            case UMSOCKET_TYPE_SCTP4ONLY_DGRAM:
            {
                int i;
                for(i=0;i< [localAddresses count];i++)
                {
                    ipAddr = [localAddresses objectAtIndex:i];
                    NSData *d = [UMSocket sockaddrFromAddress:ipAddr
                                                     port:_requestedLocalPort
                                             socketFamily:AF_INET];
                    int err = [self bindx:(struct sockaddr *)d.bytes];
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
            }
                case UMSOCKET_TYPE_SCTP6ONLY_SEQPACKET:
                case UMSOCKET_TYPE_SCTP6ONLY_STREAM:
                case UMSOCKET_TYPE_SCTP6ONLY_DGRAM:
            {
                int i;
                for(i=0;i< [localAddresses count];i++)
                {
                    ipAddr = [localAddresses objectAtIndex:i];
                    NSData *d = [UMSocket sockaddrFromAddress:ipAddr
                                                     port:_requestedLocalPort
                                             socketFamily:AF_INET6];
                    int err = [self bindx:(struct sockaddr *)d.bytes];
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
            }

#endif

            case UMSOCKET_TYPE_TCP4ONLY:
            case UMSOCKET_TYPE_UDP4ONLY:
            {
                if(localAddresses.count == 1)
                {
                    ipAddr = [localAddresses objectAtIndex:0];
                    ipAddr = [UMSocket deunifyIp:ipAddr];
                    [ipAddr getCString:addressString maxLength:255 encoding:NSUTF8StringEncoding];
                    inet_aton(addressString, &sa.sin_addr);
                }
                else
                {
                    sa.sin_addr.s_addr = htonl(INADDR_ANY);
                }
                if(bind(_sock,(struct sockaddr *)&sa,sizeof(sa)) != 0)
                {
                    eno = errno;
                    goto err;
                }
            }
                break;
            case UMSOCKET_TYPE_TCP6ONLY:
            case UMSOCKET_TYPE_UDP6ONLY:
            case UMSOCKET_TYPE_TCP:
            case UMSOCKET_TYPE_UDP:
            {
                if(localAddresses.count == 1)
                {
                    ipAddr = [localAddresses objectAtIndex:0];
                    ipAddr = [UMSocket deunifyIp:ipAddr];
                    [ipAddr getCString:addressString maxLength:255 encoding:NSUTF8StringEncoding];
                    inet_pton(AF_INET6,addressString, &sa6.sin6_addr);
                }
                else
                {
                    sa6.sin6_addr            = in6addr_any;
                }

                if(bind(_sock,(struct sockaddr *)&sa6,sizeof(sa6)) != 0)
                {
                    eno = errno;
                    goto err;
                }
                break;
            }
            default:
                return [UMSocket umerrFromErrno:EAFNOSUPPORT];
        }
        _isBound = YES;
        [self reportStatus:@"isBound=YES"];
        return UMSocketError_no_error;
    err:
        return [UMSocket umerrFromErrno:eno];
    }
    @finally
    {
        UMMUTEX_UNLOCK(_controlLock);
    }
}

-(int)bindx:(struct sockaddr *)sockaddr
{
    return UMSocketError_not_supported_operation;
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
    UMSocketError e;
    
    [self updateName];

    int err;
    [self reportStatus:@"caling listen()"];
    if (self.isListening == YES)
    {
        [self reportStatus:@"- already listening"];
        return UMSocketError_already_listening;
    }
    self.isListening = NO;
    
    UMMUTEX_LOCK(_controlLock);
    err = listen(_sock,backlog);
    UMMUTEX_UNLOCK(_controlLock);

    _direction = _direction | UMSOCKET_DIRECTION_INBOUND;
    if(err)
    {
        int eno = errno;
        e = [UMSocket umerrFromErrno:eno];
    }
    else
    {
        self.isListening = YES;
        [self reportStatus:@"isListening=YES"];
        e= UMSocketError_no_error;
    }
    return e;
}


- (UMSocketError) publish
{
#if defined(TARGET_OS_WATCH)
    return UMSocketError_not_supported_operation;
#else
    if(!self.isListening)
    {
        return UMSocketError_not_listening;
    }
    if(_advertizeDomain==NULL)
    {
        return UMSocketError_invalid_advertize_domain;
    }
    if([_advertizeType length]==0)
    {
        return UMSocketError_invalid_advertize_type;
    }
    if([_advertizeName length]==0)
    {
        return UMSocketError_invalid_advertize_name;
    }

    _netService = [[NSNetService alloc] initWithDomain:_advertizeDomain
                                         type:_advertizeType
                                         name:_advertizeName
                                         port:self.requestedLocalPort];
    [_netService scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_netService setDelegate:self];
    [_netService publish];
#endif
    return UMSocketError_no_error;
}

- (UMSocketError) unpublish
{
#if defined(TARGET_OS_WATCH)
    return UMSocketError_not_supported_operation;
#else

    [_netService stop];
    _netService=NULL;
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
    fprintf(stderr,"netService:didNotPublish:%s",errorDict.description.UTF8String);

}

- (void)netServiceDidStop:(NSNetService *)sender
{
    //NSLog(@"netServiceDidStop:");
}
#endif


- (UMSocketError) connect
{
    UMMUTEX_LOCK(_controlLock);
    @try
    {
        struct sockaddr_in	sa;
        struct sockaddr_in6	sa6;
        char addr[256];
        int err;
        _ip_version = 0;
        NSString *address;
        int resolved;

        if(self.isConnected)
        {
            fprintf(stderr,"connecting an already connected socket!?");
            return UMSocketError_is_already_connected;
        }

        if((_sock < 0) || (!_hasSocket))
        {
            _isConnecting = NO;
            self.isConnected = NO;
            return  [UMSocket umerrFromErrno:EBADF];
        }

        memset(&sa,0x00,sizeof(sa));
        sa.sin_family		= AF_INET;
#ifdef	HAS_SOCKADDR_LEN
        sa.sin_len			= sizeof(struct sockaddr_in);
#endif
        sa.sin_port         = htons(_requestedRemotePort);

        memset(&sa6,0x00,sizeof(sa6));
        sa6.sin6_family			= AF_INET6;
#ifdef	HAS_SOCKADDR_LEN
        sa6.sin6_len        = sizeof(struct sockaddr_in6);
#endif
        sa6.sin6_port       = htons(_requestedRemotePort);

        while((resolved = [_remoteHost resolved]) == 0)
        {
            usleep(50000);
        }
        address = [_remoteHost address:(UMSocketType)_type];
        if (!address)
        {
            fprintf(stderr,"[UMSocket connect] EADDRNOTAVAIL (address not resolved) during connect");
            _isConnecting = NO;
            self.isConnected = NO;
            return UMSocketError_address_not_available;
        }
        address = [UMSocket deunifyIp:address];
        [address getCString:addr maxLength:255 encoding:NSUTF8StringEncoding];
        if( inet_pton(AF_INET6, addr, &sa6.sin6_addr) == 1)
        {
            _ip_version = 6;
        }
        else if(inet_pton(AF_INET, addr, &sa.sin_addr) == 1)
        {
            _ip_version = 4;
        }
        else
        {
            fprintf(stderr,"[UMSocket connect] EADDRNOTAVAIL (unknown IP family) during connect");
            fprintf(stderr," address=%s",address.UTF8String);
            _isConnecting = NO;
            self.isConnected = NO;
            return UMSocketError_address_not_available;
        }

        if((_socketFamily==AF_INET6) && (_ip_version==4))
        {
            /* we have a IPV6 socket but the remote addres is in IPV4 format so we must use the IPv6 representation of it */
            NSString *ipv4_in_ipv6 =[NSString stringWithFormat:@"::ffff:%@",address];
            if( inet_pton(AF_INET6, ipv4_in_ipv6.UTF8String, &sa6.sin6_addr) == 1)
            {
                _ip_version = 6;
            }
            else
            {
                fprintf(stderr,"[UMSocket connect] EADDRNOTAVAIL (unknown IP family) during connect");
                _isConnecting = NO;
                self.isConnected = NO;
                return UMSocketError_address_not_available;
            }
        }
        _direction = _direction | UMSOCKET_DIRECTION_OUTBOUND;
        _isConnecting = YES;
        [self reportStatus:@"calling connect()"];
        if(_ip_version==6)
        {
            err = connect(_sock, (struct sockaddr *)&sa6, sizeof(sa6));
        }
        else if(_ip_version==4)
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

            _isConnecting = YES;
            self.isConnected = NO;
            //		goto err;
        }
        else
        {
            _isConnecting = YES;
            self.isConnected = YES;
            _status = UMSOCKET_STATUS_IS;
            NSString *msg = [NSString stringWithFormat:@"socket %d isConnected=YES",_sock];
            [self reportStatus:msg];
            return 0;
        }

        //err:
        int eno = errno;

        fprintf(stderr,"[UMSocket connect] failed with errno %d (%s)", eno, strerror(eno));
        fflush(stderr);
        return [UMSocket umerrFromErrno:eno];
    }
    @finally
    {
        UMMUTEX_UNLOCK(_controlLock);
    }
}

- (UMSocket *) init
{
    return [self initWithName:@"untitled"];
}

- (UMSocket *) initWithName:(NSString *)name
{
    self = [super init];
    if(self)
    {
        _socketName = name;
        _sock = -1;
        _cryptoStream = [[UMCrypto alloc] init];
        _controlLock = [[UMMutex alloc]initWithName:[NSString stringWithFormat:@"socket-control-lock (%@)",_socketName]];
        _dataLock = [[UMMutex alloc]initWithName:[NSString stringWithFormat:@"socket-data-lock (%@)",_socketName]];
    }
    return self;
}

- (UMSocket *) copyWithZone:(NSZone *)zone
{
    
    UMSocket *newsock = [[UMSocket alloc]initWithName:[NSString stringWithFormat:@"%@ copy",_socketName]];
    newsock.type = _type;
    newsock.direction =  _direction;
    newsock.status=_status;
    newsock.localHost = _localHost;
    newsock.remoteHost = _remoteHost;
    newsock.requestedLocalPort=_requestedLocalPort;
    newsock.requestedRemotePort=_requestedRemotePort;
    newsock.cryptoStream = [_cryptoStream copy];
/* we do not copy the socket on purpose as this is used from accept() */
    newsock->_sock=-1;
    newsock->_hasSocket=NO;
    newsock.isBound=_isBound;
    newsock.isListening=self.isListening;
    newsock.isConnecting=self.isConnecting;
    newsock.isConnected=self.isConnected;
    return newsock;
}

- (void) setLocalPort:(in_port_t) port
{
	_requestedLocalPort = port;
}

- (void) setRemotePort:(in_port_t) port
{
	_requestedRemotePort = port;
}

- (in_port_t) localPort
{
	return _connectedLocalPort;
}

- (in_port_t) remotePort
{
	return _connectedRemotePort;
}

- (NSString *)getRemoteAddress
{
    return self.connectedRemoteAddress;
}

- (void) doInitReceiveBuffer
{
    UMMUTEX_LOCK(_dataLock);
    _receiveBuffer = [[NSMutableData alloc] init];
    _receivebufpos = 0;
    UMMUTEX_UNLOCK(_dataLock);
}

- (void) deleteFromReceiveBuffer:(NSUInteger)bytes
{
    UMMUTEX_LOCK(_dataLock);
    long len;

    if (bytes > (len = [_receiveBuffer length]))
    {
        bytes = (unsigned int)len;
    }
    [_receiveBuffer replaceBytesInRange:NSMakeRange(0, bytes) withBytes:nil length:0];
    _receivebufpos -= bytes;
    if (_receivebufpos < 0)
    {
        _receivebufpos = 0;
    }
    UMMUTEX_UNLOCK(_dataLock);
}

- (UMSocket *) accept:(UMSocketError *)ret
{
    UMMUTEX_LOCK(_controlLock);
    @try
    {
        int		newsock = -1;
        UMSocket *newcon =NULL;
        NSString *remoteAddress=@"";
        in_port_t remotePort=0;
        if(UMSOCKET_IS_IPV4_ONLY_TYPE(_type))
        {
            struct	sockaddr_in sa4;
            socklen_t slen4 = sizeof(sa4);
            newsock = accept(_sock,(struct sockaddr *)&sa4,&slen4);
            if(newsock >=0)
            {
                char hbuf[NI_MAXHOST];
                char sbuf[NI_MAXSERV];
                if (getnameinfo((struct sockaddr *)&sa4, slen4, hbuf, sizeof(hbuf), sbuf,
                                sizeof(sbuf), NI_NUMERICHOST | NI_NUMERICSERV))
                {
                    remoteAddress = @"ipv4:0.0.0.0";
                    remotePort = 0;
                }
                else
                {
                    remoteAddress = @(hbuf);
                    remoteAddress = [NSString stringWithFormat:@"ipv4:%@", remoteAddress];
                    remotePort = sa4.sin_port;
                }
                TRACK_FILE_SOCKET(newsock,remoteAddress);
            }
        }
        else
        {
            /* IPv6 or dual mode */
            struct	sockaddr_in6		sa6;
            socklen_t slen6 = sizeof(sa6);
            newsock = accept(_sock,(struct sockaddr *)&sa6,&slen6);
            if(newsock >= 0)
            {
                char hbuf[NI_MAXHOST], sbuf[NI_MAXSERV];
                if (getnameinfo((struct sockaddr *)&sa6, slen6, hbuf, sizeof(hbuf), sbuf,
                                sizeof(sbuf), NI_NUMERICHOST | NI_NUMERICSERV))
                {
                    remoteAddress = @"ipv6:[::]";
                    remotePort = 0;
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
            newcon = [[UMSocket alloc]initWithName:[NSString stringWithFormat:@"%@ copy",_socketName]];
            newcon.type = _type;
            newcon.cryptoStream.fileDescriptor = newsock;

            if((_type == UMSOCKET_TYPE_TCP) || (_type == UMSOCKET_TYPE_TCP4ONLY) || (_type == UMSOCKET_TYPE_TCP6ONLY))
            {
                newcon.configuredMaxSegmentSize = _configuredMaxSegmentSize;
                newcon.activeMaxSegmentSize = _activeMaxSegmentSize;
                int currentActiveMaxSegmentSize = 0;
                socklen_t tcp_maxseg_len = sizeof(currentActiveMaxSegmentSize);
                if(getsockopt(_sock, IPPROTO_TCP, TCP_MAXSEG, &currentActiveMaxSegmentSize, &tcp_maxseg_len) == 0)
                {
                    newcon.activeMaxSegmentSize = _activeMaxSegmentSize;
                    if((_configuredMaxSegmentSize > 0) && (_configuredMaxSegmentSize < currentActiveMaxSegmentSize))
                    {
                        _activeMaxSegmentSize = _configuredMaxSegmentSize;
                        if(setsockopt(_sock, IPPROTO_TCP, TCP_MAXSEG, &_activeMaxSegmentSize, tcp_maxseg_len))
                        {
                            newcon.activeMaxSegmentSize = _configuredMaxSegmentSize;
                        }
                    }
                }
            }
            newcon.direction =  _direction;
            newcon.status=_status;
            newcon.localHost = _localHost;
            newcon.remoteHost = _remoteHost;
            newcon.requestedLocalPort=_requestedLocalPort;
            newcon.requestedRemotePort=_requestedRemotePort;
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
            newcon.useSSL = _useSSL;
            [newcon updateName];
            newcon.objectStatisticsName = @"UMSocket(accept)";
            [self reportStatus:@"accept () successful"];
            /* TODO: start SSL if required here */
            *ret = UMSocketError_no_error;
            return newcon;
        }
        *ret = [UMSocket umerrFromErrno:errno];
        return nil;
    }
    @finally
    {
        UMMUTEX_UNLOCK(_controlLock);
    }
}

- (UMSocketError) switchToNonBlocking
{
    UMSocketError returnValue = UMSocketError_no_error;
    int flags;
    int err;

    if(_blockingMode != SocketBlockingMode_isNotBlocking)
    {
        UMMUTEX_LOCK(_controlLock);
        flags = fcntl(_sock, F_GETFL, 0);
        err = fcntl(_sock, F_SETFL, flags  | O_NONBLOCK);
        UMMUTEX_UNLOCK(_controlLock);
        if(err<0)
        {
            returnValue = [UMSocket umerrFromErrno:errno];
        }
        else
        {
            _blockingMode = SocketBlockingMode_isNotBlocking;
        }
    }
    return returnValue;
}

- (UMSocketError) switchToBlocking
{
    UMSocketError returnValue = UMSocketError_no_error;
    int flags;
    int err;

    if(_blockingMode != SocketBlockingMode_isBlocking)
    {
        UMMUTEX_LOCK(_controlLock);
        flags = fcntl(_sock, F_GETFL, 0);
        err = fcntl(_sock, F_SETFL, flags  & ~O_NONBLOCK);
        UMMUTEX_UNLOCK(_controlLock);
        if(err<0)
        {
            returnValue = [UMSocket umerrFromErrno:errno];
        }
        else
        {
            _blockingMode = SocketBlockingMode_isBlocking;
        }
    }
    return returnValue;
}

- (UMSocketError) close
{
    UMSocketError err = UMSocketError_no_error;
    if((self.hasSocket) && (_sock >=0))
    {
        UMMUTEX_LOCK(_controlLock);
        TRACK_FILE_CLOSE(_sock);
        int res = close(_sock);
        if (res)
        {
            int eno = errno;
            err = [UMSocket umerrFromErrno:eno];
        }
        _sock=-1;
        self.hasSocket=NO;
        _status = UMSOCKET_STATUS_OFF;
        self.isConnected = NO;
        UMMUTEX_UNLOCK(_controlLock);
    }
    return err;
}

- (UMSocketError)sendBytes:(void *)bytes length:(ssize_t)length
{
    ssize_t i;
    int eno = 0;
    
    if(length == 0)
    {
        return UMSocketError_no_error;
    }
    switch(_type)
    {
        case UMSOCKET_TYPE_NONE:
            return UMSocketError_no_error;
            break;
            
        case UMSOCKET_TYPE_TCP4ONLY:
        case UMSOCKET_TYPE_TCP6ONLY:
        case UMSOCKET_TYPE_TCP:
        {
            if((_sock < 0) || (self.hasSocket ==NO))
            {
                self.isConnecting = NO;
                self.isConnected = NO;
                return [UMSocket umerrFromErrno:EBADF];
            }

            if(!self.isConnected)
            {
                self.isConnecting = NO;
                self.isConnected = NO;
                return [UMSocket umerrFromErrno:ECONNREFUSED];
            }
            
            
            UMSocketError err = [self switchToBlocking];
            if(err!= UMSocketError_no_error)
            {
                NSLog(@"can not switch to blocking mode ");
            }
            UMMUTEX_LOCK(_dataLock);
            i = [_cryptoStream writeBytes:bytes length:length errorCode:&eno];
            UMMUTEX_UNLOCK(_dataLock);
            err = [self switchToNonBlocking];
            if(err!= UMSocketError_no_error)
            {
                NSLog(@"can not switch to non blocking mode ");
            }

            if (i != length)
            {
                NSString *msg = [NSString stringWithFormat:@"[UMSocket: sendBytes] socket %d (status %d) returns %d errno = %d",_sock,_status, [UMSocket umerrFromErrno:eno],eno];
                [self.logFeed info:0 inSubsection:@"Universal socket" withText:msg];
                return [UMSocket umerrFromErrno:eno];
            }
            break;
        }
        case UMSOCKET_TYPE_UDP4ONLY:
        case UMSOCKET_TYPE_UDP6ONLY:
        case UMSOCKET_TYPE_UDP:
        {
            if((_sock < 0) || (self.hasSocket ==NO))
            {
                self.isConnecting = NO;
                self.isConnected = NO;
                return [UMSocket umerrFromErrno:EBADF];
            }

            if(!self.isConnected)
            {
                self.isConnecting = NO;
                self.isConnected = NO;
                return [UMSocket umerrFromErrno:ECONNREFUSED];
            }
            UMMUTEX_LOCK(_dataLock);
            i = [_cryptoStream writeBytes:bytes length:length errorCode:&eno];
            UMMUTEX_UNLOCK(_dataLock);

            if (i != length)
            {
                NSString *msg = [NSString stringWithFormat:@"[UMSocket: sendBytes] socket %d (status %d) returns %d errno = %d",_sock,_status, [UMSocket umerrFromErrno:eno],eno];
                [self.logFeed info:0 inSubsection:@"Universal socket" withText:msg];
                return [UMSocket umerrFromErrno:eno];
            }
            break;
        }
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
    @autoreleasepool
    {
        data = [str dataUsingEncoding:NSUTF8StringEncoding];
        ret =  [self sendBytes:(void *)[data bytes] length:[data length]];
        return ret;
    }
}

- (int) send:(NSMutableData *)data
{
    ssize_t i;
    int eno = 0;
    switch(_type)
    {
#if defined(UM_TRANSPORT_SCTP_SUPPORTED)
        case UMSOCKET_TYPE_SCTP:
        case UMSOCKET_TYPE_SCTP_DGRAM:
        case UMSOCKET_TYPE_SCTP_STREAM:
        case UMSOCKET_TYPE_SCTP4ONLY:
        case UMSOCKET_TYPE_SCTP4ONLY_DGRAM:
        case UMSOCKET_TYPE_SCTP4ONLY_STREAM:
            [self sendSctp:data withStreamID: 0 withProtocolID: 0]
            break;
#endif
        case UMSOCKET_TYPE_TCP4ONLY:
        case UMSOCKET_TYPE_TCP6ONLY:
        case UMSOCKET_TYPE_TCP:
        {

            if((_sock < 0) || (self.hasSocket ==NO))
            {
                self.isConnecting = NO;
                self.isConnected = NO;
                return [UMSocket umerrFromErrno:EBADF];

            }

            if(!self.isConnected)
            {
                self.isConnecting = NO;
                self.isConnected = NO;
                return [UMSocket umerrFromErrno:EINVAL];
            }
            UMMUTEX_LOCK(_dataLock);
            i =    [_cryptoStream writeBytes: [data bytes] length:[data length]  errorCode:&eno];
            UMMUTEX_UNLOCK(_dataLock);

            if (i != [data length])
            {
                return [UMSocket umerrFromErrno:eno];
            }
            break;
        }
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
    if(_sock<0)
    {
        NSLog(@"dataIsAvailable: Invalid File Socket");
        return UMSocketError_invalid_file_descriptor;
    }
    struct pollfd pollfds[1];
    int ret1;
    int ret2;
    int eno = 0;
    
    int events = POLLIN | POLLPRI | POLLERR | POLLHUP | POLLNVAL;
    
    memset(pollfds,0,sizeof(pollfds));
    pollfds[0].fd = _sock;
    pollfds[0].events = events;
    UMAssert(timeoutInMs<200000,@"timeout should be smaller than 200seconds");
    UMAssert(((timeoutInMs>100) || (timeoutInMs !=0) || (timeoutInMs !=-1)),@"timeout should be bigger than 100ms");

    errno = 99;

    UMMUTEX_LOCK(_controlLock);
    ret1 = poll(pollfds, 1, timeoutInMs);
    UMMUTEX_UNLOCK(_controlLock);

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
        if(ret2 & POLLERR)
        {
            return [UMSocket umerrFromErrno:eno];
        }
        else if(ret2 & POLLHUP)
        {
            return UMSocketError_has_data_and_hup;
        }
        
        else if(ret2 & POLLNVAL)
        {
            return [UMSocket umerrFromErrno:eno];
        }
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


+ (NSArray *)dataIsAvailableOnSockets:(NSArray *)inputSockets
                            timeoutMs:(int)timeoutInMs
                                  err:(UMSocketError *)err
{
    NSMutableArray *returnArray = [[NSMutableArray alloc]init];
    NSInteger n = inputSockets.count;
    struct pollfd *pollfds = calloc(inputSockets.count,sizeof(struct pollfd));
    
    UMAssert(timeoutInMs<200000,@"timeout should be smaller than 20seconds");
    UMAssert( ((timeoutInMs<100 ) && (timeoutInMs>0) ),@"timeout should be bigger than 100ms");

    int ret1;
    int ret2;
    int eno = 0;
    
    int events = POLLIN | POLLPRI | POLLERR | POLLHUP | POLLNVAL;
    

    for(NSInteger i=0;i<n;i++)
    {
        UMSocket *s = inputSockets[i];
        pollfds[i].fd = s.sock;
        pollfds[i].events = events;
        s.isInPollCall = YES;
    }
    errno = 0;
    ret1 = poll(pollfds, 1, timeoutInMs);
    
    if (ret1 < 0)
    {
        eno = errno;
        /* error condition */
        if (eno == EINTR)
        {
            *err = [UMSocket umerrFromErrno:eno];
        }
    }
    else if (ret1 == 0)
    {
        *err = UMSocketError_no_data;
    }
    else
    {
        *err = 0;
        /* we have some event to handle. */
        for(NSInteger i=0;i<n;i++)
        {
            UMSocket *s = inputSockets[i];
            s.isInPollCall = NO;
            ret2 = pollfds[i].revents;
            if(ret2 & POLLERR)
            {
                [returnArray addObject: @{ @"socket":s,
                                           @"data": @NO,
                                           @"hup" : @NO,
                                           @"error" : @([UMSocket umerrFromErrno:eno])}];
            }
            else if(ret2 & POLLHUP)
            {
                [returnArray addObject: @{ @"socket":s,
                                           @"data": @YES,
                                           @"hup" : @YES,
                                           @"error" : @(0)}];

            }
            else if(ret2 & POLLNVAL)
            {
                [returnArray addObject: @{ @"socket":s,
                                           @"data": @NO,
                                           @"hup" : @NO,
                                           @"error" : @([UMSocket umerrFromErrno:eno])}];
            }
            else if(ret2 & POLLIN)
            {
                [returnArray addObject: @{ @"socket":s,
                                           @"data" : @YES,
                                           @"hup" : @NO,
                                           @"error" : @(0)}];
            }
            else if(ret2 & POLLPRI)
            {
                [returnArray addObject: @{ @"socket":s,
                                           @"data" : @YES,
                                           @"hup" : @NO,
                                           @"error" : @(0)}];
            }
        }
    }
    if(pollfds)
    {
        free(pollfds);
        pollfds = NULL;
    }
    return returnArray;
}

- (UMSocketError) writeSingleChar:(unsigned char)c
{
    int eno = 0;
    [_cryptoStream writeBytes:&c length:1 errorCode:&eno];
    if(eno)
    {
        return [UMSocket umerrFromErrno:eno];
    }
    return UMSocketError_no_error;
}

- (UMSocketError) receiveSingleChar:(unsigned char *)cptr
{
    int eno = 0;
    ssize_t actualReadBytes = [_cryptoStream readBytes:cptr length:1 errorCode:&eno];
    if (actualReadBytes < 0)
    {
        if((eno != EWOULDBLOCK) && (eno != EAGAIN) && (eno != EINTR))
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
    if(actualReadBytes == 1)
    {
        return UMSocketError_has_data;
    }
    return UMSocketError_no_error;
}

- (UMSocketError) receiveEverythingTo:(NSData **)toData
{
    UMSocketError ret;
    ssize_t actualReadBytes = 0;
	unsigned char chunk[UMBLOCK_READ_SIZE];

    //*toData = nil;
    int eno = 0;

    if ([_receiveBuffer length] == 0)
    {
        
        actualReadBytes = [_cryptoStream readBytes:chunk length:sizeof(chunk) errorCode:&eno];
        eno = errno;

        if (actualReadBytes < 0)
        {
            if((eno != EWOULDBLOCK) && (eno != EAGAIN) && (eno != EINTR))
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
        [_receiveBuffer appendBytes:chunk length:actualReadBytes];
        if ([_receiveBuffer length] == 0) 
        {
            ret = [UMSocket umerrFromErrno:eno];
            return ret;
        }
    }    
    *toData = [_receiveBuffer subdataWithRange:NSMakeRange(0, [_receiveBuffer length])];
    [_receiveBuffer replaceBytesInRange:NSMakeRange(0, [_receiveBuffer length]) withBytes:nil length:0];
    _receivebufpos = 0;
        
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
    
    ret = [self switchToNonBlocking];
    if(ret != UMSocketError_no_error)
    {
        NSLog(@"can not switch to non blocking mode");
    }
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
         actualReadBytes = [_cryptoStream readBytes: chunk length:wantReadBytes errorCode:&eno];
         
         if(actualReadBytes < 0)
         {
             if((eno != EWOULDBLOCK) && (eno != EAGAIN) && (eno != EINTR))
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

- (void) reportError:(UMSocketError )err withString: (NSString *)errString
{
    NSString *errString1 = [UMSocket getSocketErrorString:err];
    fprintf(stderr,"Error: %d %s %s",err,errString1.UTF8String,errString.UTF8String);
}


- (void) reportStatus: (NSString *)str
{
    if(_reportDelegate)
    {
        [_reportDelegate reportStatus:str];
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

    if(_sock <0)
    {
        self.connectedLocalAddress = @"(closed)";
        self.connectedRemoteAddress = @"(closed)";
        self.connectedRemotePort = 0;
        self.connectedLocalPort = 0;
        return;
    }

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
    UMMUTEX_LOCK(_controlLock);
    getsockname(_sock, &sa_local, &len);
    UMMUTEX_UNLOCK(_controlLock);

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
    
    proto = [UMSocket socketTypeDescription:_type];
    switch(_type)
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
        case UMSOCKET_TYPE_SCTP_SEQPACKET:
        case UMSOCKET_TYPE_SCTP_DGRAM:
        case UMSOCKET_TYPE_SCTP_STREAM:
        case UMSOCKET_TYPE_SCTP4ONLY_SEQPACKET:
        case UMSOCKET_TYPE_SCTP4ONLY_DGRAM:
        case UMSOCKET_TYPE_SCTP4ONLY_STREAM:
        case UMSOCKET_TYPE_SCTP6ONLY_SEQPACKET:
        case UMSOCKET_TYPE_SCTP6ONLY_DGRAM:
        case UMSOCKET_TYPE_SCTP6ONLY_STREAM:
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
        switch(_direction)
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
        _name = [[NSString alloc] initWithFormat: @"%@://%@%@",proto,host,device];
    }
    else
    {
        _name = [[NSString alloc] initWithFormat: @"%@://%@/",proto,host];
    }
    self.connectedLocalAddress = xconnectedLocalAddress;
    self.connectedRemoteAddress = xconnectedRemoteAddress;
    self.connectedRemotePort = xconnectedRemotePort;
    self.connectedLocalPort = xconnectedLocalPort;
    host = nil;
}

- (void) setEvent: (int) event
{
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
    
    e = [self switchToNonBlocking];
    if(e != UMSocketError_no_error)
    {
        NSLog(@"can not switch to non blocking mode");
    }
    remainingBytes = max - [_receiveBuffer length];
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

        eno = 0;
        actualReadBytes = [_cryptoStream readBytes:chunk
                                           length:wantReadBytes
                                        errorCode:&eno];
        totalReadBytes += actualReadBytes;
        if(actualReadBytes == 0) /* SIGHUP */
        {
            if(totalReadBytes==0)
            {
                e = UMSocketError_try_again;
                if(eno)
                {
                    e = [UMSocket umerrFromErrno:eno];
                }
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
            [_receiveBuffer appendBytes:chunk length:actualReadBytes];
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

    sErr = [self switchToNonBlocking];
    if(sErr != UMSocketError_no_error)
    {
        NSLog(@"can not switch to non blocking mode");
    }

    int eno = 0;
    
    *toData = nil;

    pos = [_receiveBuffer rangeOfData_dd:eol startingFrom:_receivebufpos];
    if (pos.location == NSNotFound)
    {
        actualReadBytes = [_cryptoStream readBytes:chunk
                                       length:sizeof(chunk)
                                    errorCode:&eno];
        if (actualReadBytes <= 0)
        {
            if ((eno == EINTR) || (eno == EAGAIN) || (eno == EWOULDBLOCK))
            {
                usleep(10000);
                return UMSocketError_try_again;
            }
            else
            {
                fprintf(stderr,"we have socket err %d set error %d", errno, eno);
                sErr = [UMSocket umerrFromErrno:eno];
                return sErr;
            }
        }
        
        [_receiveBuffer appendBytes:chunk length:actualReadBytes];
        pos = [_receiveBuffer rangeOfData_dd:eol startingFrom:_receivebufpos];
        if (pos.location == NSNotFound)
        {
            fprintf(stderr,"we have no eol");
            return UMSocketError_no_error;
        }
    }
    
    NSMutableData *tmp = [[_receiveBuffer subdataWithRange:NSMakeRange(_receivebufpos, pos.location - _receivebufpos)]mutableCopy];
    if([tmp length]==0)
    {
        *toData = NULL;
        return UMSocketError_no_error;
    }
    *toData = tmp;
    [self deleteFromReceiveBuffer:pos.location+pos.length];
    _receivebufpos = 0;
    return UMSocketError_no_error;
}


- (UMSocketError) receive:(long)bytes to:(NSData **)returningData
{
    long i;
    ssize_t actualReadBytes;
    unsigned char chunk[UMBLOCK_READ_SIZE];
    UMSocketError sErr;
    
    sErr = [self switchToNonBlocking];
    if(sErr != UMSocketError_no_error)
    {
        NSLog(@"can not switch to non blocking mode");
    }

    *returningData = nil;
   // NSLog(@"[UMsocket receive:to:] %@", [self fullDescription]);
    
    /* skip heading spaces */
    if(_receivebufpos > 0)
    {
        /* remove heading */
        [_receiveBuffer replaceBytesInRange:NSMakeRange(0, _receivebufpos) withBytes:nil length:0];
        _receivebufpos = 0;
    }

    i = _receivebufpos;
    const unsigned char *c = _receiveBuffer.bytes;
    NSUInteger len = _receiveBuffer.length;
    while(i<len)
    {
        if (!isspace(c[0]))
        {
            break;
        }
        i++;
    }
    [self deleteFromReceiveBuffer:i];

    size_t start = _receivebufpos;
    size_t end = bytes + _receivebufpos;
    int eno = 0;
    while ([_receiveBuffer length] < end)
    {
        size_t remainingSize =  end - start - [_receiveBuffer length];
        if(remainingSize > sizeof(chunk))
        {
            actualReadBytes = [_cryptoStream readBytes:chunk
                                           length:sizeof(chunk)
                                        errorCode:&eno];
        }
        else
        {
            actualReadBytes = [_cryptoStream readBytes:chunk
                                           length:remainingSize
                                        errorCode:&eno];
        }
        eno = errno;
        if (actualReadBytes <= 0)
        {
            if ((eno == EINTR) || (eno == EAGAIN) || (eno == EWOULDBLOCK))
            {
                usleep(10000);
                return UMSocketError_try_again;
            }
            else
            {
                sErr = [UMSocket umerrFromErrno:eno];
                return sErr;
            }
        }
        else
        {
            [_receiveBuffer appendBytes:&chunk[0] length:actualReadBytes];
        }
    }
    
    NSData *resultData = [_receiveBuffer subdataWithRange:NSMakeRange(_receivebufpos, bytes)];
    *returningData  = resultData;
    
    [_receiveBuffer replaceBytesInRange:NSMakeRange(0, end) withBytes:nil length:0];
    _receivebufpos = 0;
    return UMSocketError_no_error;
}

-(void)sendNow
{
}

+ (UMSocketError) umerrFromErrno:(int)e
{
	switch(e)
    {
        case 0:
            return UMSocketError_no_error;
        case EACCES:
            return UMSocketError_insufficient_privileges;
        case EADDRINUSE:
            return UMSocketError_address_already_in_use;
        case EADDRNOTAVAIL:
            return UMSocketError_address_not_available;
        case EAFNOSUPPORT:
            return UMSocketError_address_not_valid_for_socket_family;
        case EBADF:
            NSLog(@"UMErrFromErrno: Invalid File Socket");
            return UMSocketError_invalid_file_descriptor;
        case EFAULT:
            return UMSocketError_pointer_not_in_userspace;
        case EINVAL:
            return UMSocketError_invalid_port_or_address;
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
#if defined(EMSGSIZE)
        case EMSGSIZE:
#endif
            return UMSocketError_no_space_left;
        case EPIPE:
            return UMSocketError_pipe_error;
        case ESRCH:
            return UMSocketError_no_such_process;
        case EHOSTDOWN:
            return UMSocketError_host_down;
        case ENOTCONN:
            return UMSocketError_not_connected;
        case ECONNABORTED:
            return UMSocketError_connection_aborted;
#if defined EBUSY
        case EBUSY:
            return UMSocketError_busy;
#endif
        case EINPROGRESS:
            return UMSocketError_in_progress;

#if defined EALREADY
        case EALREADY:
#endif
        case EISCONN:
            return UMSocketError_is_already_connected;
        default:
            fprintf(stderr,"Unknown errno code %d %s\n",e,strerror(e));
            return UMSocketError_not_known;
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
            return @"address_not_valid_for_socket_socketFamily";
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
            return @"try-again";
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
        case UMSocketError_no_data:
            return @"no data";
        case UMSocketError_not_listening:
            return @"not listening";
        case UMSocketError_invalid_advertize_domain:
            return @"invalid advertize domain";
        case UMSocketError_invalid_advertize_type:
            return @"invalid advertize type";
        case UMSocketError_invalid_advertize_name:
            return @"invalid advertize name";
        case UMSocketError_no_such_process:
            return @"no such process";
        case UMSocketError_connection_aborted:
            return @"connection aborted";
        case UMSocketError_in_progress:
            return @"in progress";
        case UMSocketError_invalid_port_or_address:
            return @"invalid port or address";
        case UMSocketError_is_already_connected:
            return @"socket is already connected";
        case UMSocketError_file_descriptor_not_open:
            return @"file descriptor is not open";
        case UMSocketError_protocol_violation:
            return @"protocol violation";
        case UMSocketError_busy:
            return @"busy";
        case UMSocketError_not_known:
            return @"not known";
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
    @autoreleasepool
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
        if([addr hasPrefix:@"::ffff:"])
        {
            addr = [addr substringFromIndex:7];
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
}

+(NSString *)deunifyIp:(NSString *)addr
{
    return [UMSocket deunifyIp:addr type:NULL];
}

+(NSString *)deunifyIp:(NSString *)addr type:(int *)t
{
    int dummy_t;
    if(t==NULL)
    {
        t = &dummy_t;
    }
    @autoreleasepool
    {
        if(([addr isEqualToString:@"ipv6:[::]"]) || ([addr isEqualToString:@"[::]"]) || ([addr isEqualToString:@"::"]))
        {
            *t = 6;
            return @"::";
        }
        if(([addr isEqualToString:@"ipv4:0.0.0.0"]) || ([addr isEqualToString:@"0.0.0.0"]))

        {
            *t = 6;
            return @"0.0.0.0";
        }
        if(([addr isEqualToString:@"ipv6:localhost"]) || ([addr isEqualToString:@"ipv6:[::1]"]) || ([addr isEqualToString:@"ipv6:::1"]) || ([addr isEqualToString:@"::1"]))
        {
            *t = 6;
            return @"::1";
        }

        if(([addr isEqualToString:@"ipv4:localhost"]) || ([addr isEqualToString:@"ipv4:127.0.0.1"]) || ([addr isEqualToString:@"127.0.0.1"])|| ([addr isEqualToString:@"localhost"]))
        {
            *t = 4;
            return @"127.0.0.1";
        }
        if(addr.length >=4)
        {
            NSString *addrtype =   [addr substringToIndex:4];
            if([addrtype isEqualToString:@"ipv4"])
            {
                if(t)
                {
                    *t = 4;
                }
                NSInteger start = 5;
                NSInteger len = [addr length] - start;
                if(len < 1)
                {
                    if(t)
                    {
                        *t = 0;
                    }
                    return @"";
                }
                return [addr substringWithRange:NSMakeRange(start,len)];
            }
            
            else if([addrtype isEqualToString:@"ipv6"])  /* format: ipv6:[xxx:xxx:xxx...:xxxx] */
            {
                if(t)
                {
                    *t = 6;
                }
                NSInteger start = 5;
                NSInteger len = [addr length] -1 - start;
                if(len < 1)
                {
                    if(t)
                    {
                        *t = 0;
                    }
                    return NULL;
                }
                return [addr substringWithRange:NSMakeRange(start,len)];
            }
        }
        if([addr isIPv4])
        {
            *t = 4;
        }
        else if([addr isIPv6])
        {
            *t = 6;
        }
        else
        {
            *t = 0;
        }
        return addr;
    }
}


#define RXBUFSIZE   (32*1024)
- (UMSocketError) receiveData:(NSData **)toData
                  fromAddress:(NSString **)address
                     fromPort:(int *)port
{
    ssize_t rxsize=0;
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
        uint16_t p=0;
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
    ssize_t sentDataSize = 0;
    int flags = MSG_DONTWAIT;
    NSData *d = [UMSocket sockaddrFromAddress:unifiedAddr port:port socketFamily:_socketFamily];
    sentDataSize = sendto(_sock,
                          [data bytes],
                          (size_t)[data length],
                          flags,
                          (struct sockaddr *)d.bytes,
                          (socklen_t) d.length);
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
    UMSocketError sErr = [self switchToNonBlocking];
    if(sErr != UMSocketError_no_error)
    {
        NSLog(@"can not switch to non blocking mode");
    }

    _ssl = (void *)SSL_new(global_server_ssl_context);
    ERR_clear_error();

    if (_serverSideCertFilename != NULL)
    {
        SSL_use_certificate_file((SSL *)_ssl, _serverSideCertFilename.UTF8String,SSL_FILETYPE_PEM);
        SSL_use_PrivateKey_file((SSL *)_ssl, _serverSideKeyFilename.UTF8String,SSL_FILETYPE_PEM);
        if (SSL_check_private_key((SSL *)_ssl) != 1)
        {
            NSString *msg = [NSString stringWithFormat:@"startTLS: private key isn't consistent with the certificate from file %@ (or failed reading the file)",_serverSideCertFilename];
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
    if (0==SSL_set_fd((SSL *)_ssl, _sock))
    {
        /* SSL_set_fd failed, log error */
        fprintf(stderr,"SSL: OpenSSL: %.256s", ERR_error_string(ERR_get_error(), NULL));
        return;
    }
    /* set to  blocking IO during the handshake */
    BIO_set_nbio(SSL_get_rbio((SSL *)_ssl), 0);
    BIO_set_nbio(SSL_get_wbio((SSL *)_ssl), 0);

    if(_direction == UMSOCKET_DIRECTION_INBOUND)
    {
        SSL_set_accept_state((SSL *)_ssl);
    }
    else if(_direction == UMSOCKET_DIRECTION_OUTBOUND)
    {
        SSL_set_connect_state((SSL *)_ssl);
    }


    while(1)
    {
        int i = SSL_do_handshake((SSL *)_ssl);
        if(i==1)
        {
            break;
        }
        else if(i<=0)
        {

            int ssl_error = SSL_get_error((SSL *)_ssl,i);
            if((ssl_error == SSL_ERROR_WANT_READ) || (ssl_error == SSL_ERROR_WANT_WRITE))
            {
                continue;
            }
            if(ssl_error == SSL_ERROR_SSL)
            {
                long e = -1;
                while(e!=0)
                {
                    e = ERR_get_error();
                    if(e)
                    {
                        //NSLog(@"SSL: %s",ERR_reason_error_string(e));
                    }
                }
                break;
            }
            break;
        }
        else
        {
            break;
        }
    }

    if(SSL_get_verify_result(_ssl) != X509_V_OK)
    {
        //NSLog(@"SSL_get_verify_result() failed"); /* Handle the failed verification */
    }
    else
    {
        /* set to  non blocking IO after the handshake */
        BIO_set_nbio(SSL_get_rbio((SSL *)_ssl), 1);
        BIO_set_nbio(SSL_get_wbio((SSL *)_ssl), 1);

        _sslActive = YES;
        _cryptoStream.enable=_sslActive;
    }
}

- (int) fileDescriptor
{
    return _sock;
}

- (void *)ssl
{
    return _ssl;
}



+ (void)initSSL
{
    if(global_server_ssl_context == NULL)
    {
        #if OPENSSL_VERSION_NUMBER < 0x10100000L
        SSL_library_init();
        SSLeay_add_ssl_algorithms();
        SSL_load_error_strings();
        #else
        OPENSSL_init_ssl(0, NULL);
        #endif

#if  defined(HAVE_TLS_METHOD) || defined(__APPLE__)
        global_generic_ssl_context = SSL_CTX_new(TLS_method());
        global_server_ssl_context = SSL_CTX_new(TLS_server_method());
        global_client_ssl_context = SSL_CTX_new(TLS_client_method());
#else
        global_generic_ssl_context = SSL_CTX_new(TLSv1_2_method());
        global_server_ssl_context = SSL_CTX_new(TLSv1_2_server_method());
        global_client_ssl_context = SSL_CTX_new(TLSv1_2_client_method()) ;
#endif

        SSL_CTX_set_mode(global_generic_ssl_context,
                         SSL_MODE_ENABLE_PARTIAL_WRITE
                         | SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER
                         | SSL_MODE_AUTO_RETRY);

        SSL_CTX_set_mode(global_client_ssl_context,
                        SSL_MODE_ENABLE_PARTIAL_WRITE
                         | SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER
                         | SSL_MODE_AUTO_RETRY );

        SSL_CTX_set_mode(global_server_ssl_context,
                         SSL_MODE_ENABLE_PARTIAL_WRITE
                         | SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER
                         | SSL_MODE_AUTO_RETRY);

        if (!SSL_CTX_set_default_verify_paths(global_server_ssl_context))
        {
            @throw ([NSException exceptionWithName:@"PANIC"
                                            reason:@"can not set default path for SSL server. SSL_CTX_set_default_verify_paths() fails"
                                          userInfo:@{@"backtrace": UMBacktrace(NULL,0)}]);

        }

#ifdef NO_LONGER_USED
        int maxlocks = CRYPTO_num_locks();
        ssl_static_locks = (ummutex_c_pointer *)malloc(sizeof(ummutex_c_pointer) * maxlocks);
        for (int c = 0; c < maxlocks; c++)
        {
            UMMutex *lck = [[UMMutex alloc]initWithName: [NSString stringWithFormat:@"ssl_static_locks[%d]",c]];
            ssl_static_locks[c] = (__bridge_retained ummutex_c_pointer)lck;
        }
#endif
    }
}

- (UMSocketError)setLinger
{
#ifdef SO_LINGER
    struct linger linger;
    linger.l_onoff  = 1;
    linger.l_linger = 5;
    int err = setsockopt(_sock, SOL_SOCKET, SO_LINGER, &linger, sizeof (struct linger));

    if(err !=0)
    {
        return [UMSocket umerrFromErrno:errno];
    }
    return UMSocketError_no_error;
#else
    return UMSocketError_not_supported_operation;
#endif
}

- (UMSocketError)setPathMtuDiscovery:(BOOL)enable
{
#ifdef IP_MTU_DISCOVER
    int i;
    if(enable)
    {
    	i = IP_PMTUDISC_DO;
    }
    else
    {
    	i = IP_PMTUDISC_DONT;
    }
    int err = setsockopt(_sock, IPPROTO_IP, IP_MTU_DISCOVER, &i, sizeof (i));

    if(err !=0)
    {
        return [UMSocket umerrFromErrno:errno];
    }
    return UMSocketError_no_error;
#else
    return UMSocketError_not_supported_operation;
#endif
}


-(UMSocketError) setReuseAddr
{
    int flags = 1;
    int err = setsockopt(_sock, SOL_SOCKET, SO_REUSEADDR, (char *)&flags, sizeof(flags));
    if(err !=0)
    {
        return [UMSocket umerrFromErrno:errno];
    }
    return UMSocketError_no_error;
}

- (UMSocketError) setIPDualStack
{
    int flag = 0;
    int err = setsockopt(_sock, IPPROTO_IPV6, IPV6_V6ONLY, (char *)&flag, sizeof(flag));
    if(err !=0)
    {
        return [UMSocket umerrFromErrno:errno];
    }
    return UMSocketError_no_error;
}

- (UMSocketError) setIPv6Only
{
    int flag = 1;
    int err = setsockopt(_sock, IPPROTO_IPV6, IPV6_V6ONLY, (char *)&flag, sizeof(flag));
    if(err !=0)
    {
        return [UMSocket umerrFromErrno:errno];
    }
    return UMSocketError_no_error;
}

- (UMSocketError) setKeepalive:(BOOL)keepalive
{
    int flag = keepalive ? 1 : 0;
    int err = setsockopt(_sock, SOL_SOCKET, SO_KEEPALIVE, (char *)&flag, sizeof(flag));
    if(err !=0)
    {
        return [UMSocket umerrFromErrno:errno];
    }
    return UMSocketError_no_error;
}

+ (NSString *)addressOfSockAddr:(struct sockaddr *)sockAddr
{
    char buf[INET6_ADDRSTRLEN+1];
    memset(buf,0x00,INET6_ADDRSTRLEN+1);
    switch(sockAddr->sa_family)
    {
        case AF_INET:
        {
            struct sockaddr_in *sa_in = (struct sockaddr_in *)sockAddr;
            const char *r = inet_ntop(sa_in->sin_family, &sa_in->sin_addr, &buf[0], INET6_ADDRSTRLEN);
            return @(r);
            break;
        }
        case AF_INET6:
        {
            struct sockaddr_in6 *sa_in6 = (struct sockaddr_in6 *)sockAddr;
            const char *r = inet_ntop(sa_in6->sin6_family, &sa_in6->sin6_addr, &buf[0], INET6_ADDRSTRLEN);
            NSString *s = @(r);
            if([s hasPrefix:@"::ffff:"])
            {
                s = [s substringFromIndex:7];
            }
            return s;
            break;
        }
        default:
            return NULL;
    }
}


+ (int)portOfSockAddr:(struct sockaddr *)sockAddr
{
    char buf[INET6_ADDRSTRLEN+1];
    memset(buf,0x00,INET6_ADDRSTRLEN+1);
    switch(sockAddr->sa_family)
    {
        case AF_INET:
        {
            struct sockaddr_in *sa_in = (struct sockaddr_in *)sockAddr;
            return ntohs (sa_in->sin_port);
            break;
        }
        case AF_INET6:
        {
            struct sockaddr_in6 *sa_in6 = (struct sockaddr_in6 *)sockAddr;
            return ntohs(sa_in6->sin6_port);
            break;
        }
        default:
            return 0;
    }
}


+ (NSData *)sockaddrFromAddress:(NSString *)theAddr
                             port:(int)thePort
                     socketFamily:(int)socketFamily
{
    NSData *resultData = NULL;
    
    NSString *address = theAddr;
    NSString *address2 = [UMSocket deunifyIp:address];
    if(address2.length>0)
    {
        address = address2;
    }

    if(socketFamily==AF_INET6)
    {
        struct sockaddr_in6 address6;
        memset(&address6,0x00,sizeof(struct sockaddr_in6));

        if([address isIPv4])
        {
            /* we have a IPV6 socket but the  addres is in IPV4 format so we must use the IPv6 representation of it */
            address = [NSString stringWithFormat:@"::ffff:%@",address];
        }
        
        int result = inet_pton(AF_INET6,address.UTF8String, &address6.sin6_addr);
        if(result==1)
        {
#ifdef HAVE_SOCKADDR_SIN_LEN
            address6.sin6_len = sizeof(struct sockaddr_in6);
#endif
            address6.sin6_family = AF_INET6;
            address6.sin6_port = htons(thePort);
            resultData = [NSData dataWithBytes:&address6 length:sizeof(address6)];
        }
        else
        {
            NSLog(@"'%@' is not a valid IPv6 address",theAddr);
        }
    }
    else if(socketFamily==AF_INET)
    {
        struct sockaddr_in  address4;
        memset(&address4,0x00,sizeof(struct sockaddr_in));
        int result = inet_pton(AF_INET,address.UTF8String, &address4.sin_addr);
        if(result==1)
        {
#ifdef HAVE_SOCKADDR_SIN_LEN
            address4.sin_len = sizeof(struct sockaddr_in);
#endif
            address4.sin_family = AF_INET;
            address4.sin_port = htons(thePort);
            resultData = [NSData dataWithBytes:&address4 length:sizeof(address4)];
        }
        else
        {
            NSLog(@"'%@' is not a valid IPv4 address",theAddr);
        }
    }
    return resultData;
}

- (UMPacket *)receivePacket
{
#define MAXBUF 65536
    
    struct sockaddr_in6     remote_address6;
    struct sockaddr_in      remote_address4;
    struct sockaddr *       remote_address_ptr;
    socklen_t               remote_address_len;
    if(_socketFamily==AF_INET)
    {
        remote_address_ptr = (struct sockaddr *)&remote_address4;
        remote_address_len = sizeof(struct sockaddr_in);
    }
    else
    {
        remote_address_ptr = (struct sockaddr *)&remote_address6;
        remote_address_len = sizeof(struct sockaddr_in6);
    }

    ssize_t                 bytes_read = 0;
    char                    buffer[MAXBUF];
    int                     flags=0;

    memset(&buffer[0],0xFA,sizeof(buffer));
    memset(remote_address_ptr,0x00,sizeof(remote_address_len));

    UMPacket *rx = [[UMPacket alloc]init];
    bytes_read = recvfrom(_sock, buffer, sizeof(buffer), flags,
        remote_address_ptr, &remote_address_len);

    rx.socket = @(_sock);

    if(bytes_read <= 0)
    {
        rx.err = [UMSocket umerrFromErrno:errno];
    }
    else
    {
        rx.remoteAddress = [UMSocket addressOfSockAddr:remote_address_ptr];
        rx.remotePort = [UMSocket portOfSockAddr:remote_address_ptr];
        rx.data = [NSData dataWithBytes:&buffer length:bytes_read];
    }
    return rx;
}


- (UMSocketError) getSocketError
{
    int eno = 0;
    socklen_t len = sizeof(int);
    getsockopt(_sock, SOL_SOCKET, SO_ERROR, &eno, &len);
    return  [UMSocket umerrFromErrno:eno];
}

- (int)configuredMaxSegmentSize
{
    return _configuredMaxSegmentSize;
}

- (void)setConfiguredMaxSegmentSize:(int)max
{
    _configuredMaxSegmentSize = max;
    if((_type == UMSOCKET_TYPE_TCP) || (_type == UMSOCKET_TYPE_TCP4ONLY) || (_type == UMSOCKET_TYPE_TCP6ONLY))
    {
        int currentActiveMaxSegmentSize = 0;
        socklen_t tcp_maxseg_len = sizeof(currentActiveMaxSegmentSize);
        if(getsockopt(_sock, IPPROTO_TCP, TCP_MAXSEG, &currentActiveMaxSegmentSize, &tcp_maxseg_len) == 0)
        {
            _activeMaxSegmentSize = currentActiveMaxSegmentSize;
            if((_configuredMaxSegmentSize > 0) && (_configuredMaxSegmentSize < currentActiveMaxSegmentSize))
            {
                _activeMaxSegmentSize = _configuredMaxSegmentSize;
                tcp_maxseg_len = sizeof(currentActiveMaxSegmentSize);
                if(setsockopt(_sock, IPPROTO_TCP, TCP_MAXSEG, &_configuredMaxSegmentSize, tcp_maxseg_len))
                {
                    _activeMaxSegmentSize = _configuredMaxSegmentSize;
                }
            }
        }
    }
}



- (void)setReceiveBufferSize:(int)bufsize
{
    setsockopt(_sock, SOL_SOCKET, SO_RCVBUF, &bufsize, sizeof(bufsize));
}

- (void)setSendBufferSize:(int)bufsize
{
    setsockopt(_sock, SOL_SOCKET, SO_SNDBUF, &bufsize, sizeof(bufsize));
}

- (int)receiveBufferSize
{
    int bufsize = 0;
    socklen_t len = sizeof(bufsize);
    if(getsockopt(_sock, SOL_SOCKET, SO_RCVBUF, &bufsize, &len) != 0)
    {
        return -1;
    }
    return bufsize;
}

- (int)sendBufferSize
{
    int bufsize = 0;
    socklen_t len = sizeof(bufsize);
    if(getsockopt(_sock, SOL_SOCKET, SO_SNDBUF, &bufsize, &len) != 0)
    {
        return -1;
    }
    return bufsize;
}


- (void)setDscpString:(NSString *)dscp
{
    dscp = [dscp uppercaseString];
    if([dscp isEqualToString:@"AF11"])
    {
        [self setDscp:10];
    }
    else if([dscp isEqualToString:@"AF12"])
    {
        [self setDscp:12];
    }
    else if([dscp isEqualToString:@"AF13"])
    {
        [self setDscp:14];
    }
    else if([dscp isEqualToString:@"AF21"])
    {
        [self setDscp:18];
    }
    else if([dscp isEqualToString:@"AF22"])
    {
        [self setDscp:20];
    }
    else if([dscp isEqualToString:@"AF23"])
    {
        [self setDscp:22];
    }
    else if([dscp isEqualToString:@"AF31"])
    {
        [self setDscp:26];
    }
    else if([dscp isEqualToString:@"AF32"])
    {
        [self setDscp:28];
    }
    else if([dscp isEqualToString:@"AF33"])
    {
        [self setDscp:30];
    }
    else if([dscp isEqualToString:@"AF41"])
    {
        [self setDscp:34];
    }
    else if([dscp isEqualToString:@"AF42"])
    {
        [self setDscp:36];
    }
    else if([dscp isEqualToString:@"AF43"])
    {
        [self setDscp:38];
    }
    else
    {
        int a = [dscp intValue];
        NSString *s = [NSString stringWithFormat:@"%d",a];
        if([s isEqualToString:dscp])
        {
            [self setDscp:a];
        }
    }
}

- (NSString *)dscpString
{
    int dscp = [self dscp];
    switch(dscp)
    {
        case 10:
            return @"AF11";
        case 12:
            return @"AF12";
        case 14:
            return @"AF13";
        case 18:
            return @"AF21";
        case 20:
            return @"AF22";
        case 22:
            return @"AF23";
        case 26:
            return @"AF31";
        case 28:
            return @"AF32";
        case 30:
            return @"AF33";
        case 34:
            return @"AF41";
        case 36:
            return @"AF42";
        default:
            if(dscp > 0)
            {
                return [NSString stringWithFormat:@"%d",dscp];
            }
    }
    return NULL;
}

- (void)setDscp:(int)dscp
{
#ifdef __APPLE__
    return;
#endif

#ifdef FREEBSD
    return;
#endif

#ifdef LINUX
    setsockopt(_sock, SOL_SOCKET, SO_PRIORITY, &dscp, sizeof(dscp));
#endif
}

- (int)dscp
{
#ifdef __APPLE__
    return -1;
#endif
#ifdef FREEBSD
    return -1;
#endif
#ifdef LINUX
    int dscp = 0;
    socklen_t len = sizeof(dscp);
    if(getsockopt(_sock, SOL_SOCKET, SO_PRIORITY, &dscp, &len) != 0)
    {
        return -1;
    }
    return dscp;
#endif
    return -1;
}

@end
