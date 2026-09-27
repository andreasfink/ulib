//
//  UMSocketSCTP.m
//  ulib
//
//  Created by Andreas Fink on 14.05.18.
//  Copyright © 2018 Andreas Fink (andreas@fink.org). All rights reserved.
//

/* Define if you have netinet/sctp.h. */
/* #undef HAVE_NETINET_SCTP_H */
#define ULIBSCTP_INTERNAL   1

#include <ulib/ulib_config.h>

#import <ulib/UMSocketSCTP.h>
#import <ulib/UMSocketSCTPListener2.h>
#import <ulib/UMHistoryLog.h>
#import <ulib/UMFileTrackingMacros.h>
#import <ulib/NSString+ulib.h>
#import <ulib/NSMutableString+ulib.h>
#import <ulib/NSData+ulib.h>
#import <ulib/NSMutableData+ulib.h>
#import <ulib/UMAssert.h>

#include <fcntl.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/poll.h>
#include <arpa/inet.h>
#include <string.h>

#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/uio.h>
#include <unistd.h>
#include <poll.h>
#include <fcntl.h>
#include <netinet/tcp.h>
#include <netdb.h>



#ifdef HAVE_SCTP_SCTP_H
#include <ulib/sctp.h>
#include <ulib/sctp_uio.h>
#endif

#if defined(HAVE_NETINET_SCTP_H)
#include <netinet/sctp.h>
#endif

#if defined(__APPLE__)
#include <sys/utsname.h>
#define MSG_NOTIFICATION_MAVERICKS 0x40000        /* notification message */
#define MSG_NOTIFICATION_YOSEMITE  0x80000        /* notification message */

#ifndef MSG_NOTIFICATION
#define MSG_NOTIFICATION MSG_NOTIFICATION_YOSEMITE
#endif

#endif


#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>
#include <poll.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <netdb.h>
#include <sys/utsname.h>
#include <string.h>

static int _global_msg_notification_mask = 0;

#ifdef LINUX
int sctp_sendv(int s, const struct iovec *iov, int iovcnt,
               struct sockaddr *addrs, int addrcnt, void *info,
               socklen_t infolen, unsigned int infotype, int flags);


int sctp_recvv(int s, const struct iovec *iov, int iovlen,
               struct sockaddr *from, socklen_t *fromlen, void *info,
               socklen_t *infolen, unsigned int *infotype, int *flags);
#endif


@implementation UMSocketSCTP

- (void)initNetworkSocket
{
    _historyLog = [[UMHistoryLog alloc]initWithMaxLines:100];
    _sock = -1;
    switch(_type)
    {
        case UMSOCKET_TYPE_SCTP4ONLY_SEQPACKET:
            _socketFamily=AF_INET;
            _socketType = SOCK_SEQPACKET;
            _socketProto = IPPROTO_SCTP;
            _sock = socket(_socketFamily,_socketType, _socketProto);
            TRACK_FILE_SOCKET(_sock,@"sctp");
            break;
        case UMSOCKET_TYPE_SCTP6ONLY_SEQPACKET:
            _socketFamily=AF_INET6;
            _socketType = SOCK_SEQPACKET;
            _socketProto = IPPROTO_SCTP;
            _sock = socket(_socketFamily,_socketType, _socketProto);
            TRACK_FILE_SOCKET(_sock,@"sctp");
            break;
        case UMSOCKET_TYPE_SCTP_SEQPACKET:
            _socketFamily=AF_INET6;
            _socketType = SOCK_SEQPACKET;
            _socketProto = IPPROTO_SCTP;
            _sock = socket(_socketFamily,_socketType, _socketProto);
            TRACK_FILE_SOCKET(_sock,@"sctp");
            if(_sock < 0)
            {
                if(errno==EAFNOSUPPORT)
                {
                    _socketFamily=AF_INET;
                    _sock = socket(_socketFamily,_socketType, _socketProto);
                    TRACK_FILE_SOCKET(_sock,@"sctp");
                    if(_sock!=-1)
                    {
                        [self setNoDelay];
                    }
                }
            }
            break;
        case UMSOCKET_TYPE_SCTP4ONLY_STREAM:
            _socketFamily=AF_INET;
            _socketType = SOCK_STREAM;
            _socketProto = IPPROTO_SCTP;
            _sock = socket(_socketFamily,_socketType, _socketProto);
            TRACK_FILE_SOCKET(_sock,@"sctp");
            break;
        case UMSOCKET_TYPE_SCTP6ONLY_STREAM:
            _socketFamily=AF_INET6;
            _socketType = SOCK_STREAM;
            _socketProto = IPPROTO_SCTP;
            _sock = socket(_socketFamily,_socketType, _socketProto);
            TRACK_FILE_SOCKET(_sock,@"sctp");
            break;
        case UMSOCKET_TYPE_SCTP_STREAM:
            _socketFamily=AF_INET6;
            _socketType = SOCK_STREAM;
            _socketProto = IPPROTO_SCTP;
            _sock = socket(_socketFamily,_socketType, _socketProto);
            TRACK_FILE_SOCKET(_sock,@"sctp");
            if(_sock < 0)
            {
                if(errno==EAFNOSUPPORT)
                {
                    _socketFamily=AF_INET;
                    _sock = socket(_socketFamily,_socketType, _socketProto);
                    TRACK_FILE_SOCKET(_sock,@"sctp");
                    if(_sock!=-1)
                    {
                        [self setNoDelay];
                    }
                }
            }
            break;
        case UMSOCKET_TYPE_SCTP4ONLY_DGRAM:
            _socketFamily=AF_INET;
            _socketType = SOCK_DGRAM;
            _socketProto = IPPROTO_SCTP;
            _sock = socket(_socketFamily,_socketType, _socketProto);
            TRACK_FILE_SOCKET(_sock,@"sctp");
            break;
        case UMSOCKET_TYPE_SCTP6ONLY_DGRAM:
            _socketFamily=AF_INET6;
            _socketType = SOCK_DGRAM;
            _socketProto = IPPROTO_SCTP;
            _sock = socket(_socketFamily,_socketType, _socketProto);
            TRACK_FILE_SOCKET(_sock,@"sctp");
            break;
        case UMSOCKET_TYPE_SCTP_DGRAM:
            _socketFamily=AF_INET6;
            _socketType = SOCK_DGRAM;
            _socketProto = IPPROTO_SCTP;
            _sock = socket(_socketFamily,_socketType, _socketProto);
            TRACK_FILE_SOCKET(_sock,@"sctp");
            if(_sock < 0)
            {
                if(errno==EAFNOSUPPORT)
                {
                    _socketFamily=AF_INET;
                    _sock = socket(_socketFamily,_socketType, _socketProto);
                    TRACK_FILE_SOCKET(_sock,@"sctp");
                    if(_sock!=-1)
                    {
                        [self setNoDelay];
                    }
                }
            }
            break;

        default:
            [super initNetworkSocket];
            break;
    }
    if(_sock > -1)
    {
        _hasSocket = YES;
    }
    else
    {
        _hasSocket = NO;
    }
    
    if(_global_msg_notification_mask==0)
    {
#ifdef __APPLE__
        int major;
        int minor;
        int sub;
        
        struct utsname ut;
        uname(&ut);
        sscanf(ut.release,"%d.%d.%d",&major,&minor,&sub);
        if(major >= 14)
        {
            _global_msg_notification_mask = MSG_NOTIFICATION_YOSEMITE;
        }
        else
        {
            _global_msg_notification_mask = MSG_NOTIFICATION_MAVERICKS;
        }
#else
        _global_msg_notification_mask = MSG_NOTIFICATION;
#endif
    }
    _msg_notification_mask = _global_msg_notification_mask;
    _status = UMSOCKET_STATUS_FOOS;
	[self switchToNonBlocking];
	[self setIPDualStack];
	[self setLinger];
	[self setReuseAddr];
	[self setPathMtuDiscovery:YES];
}

- (void)prepareLocalAddresses
{
    if((_localAddressesSockaddr==NULL) || ( _localAddressesSockaddrCount==0))
    {
        int  _localAddressesSockaddrCount;
        _localAddressesSockaddr = [UMSocketSCTP sockaddrFromAddresses:_requestedLocalAddresses
                                                                 port:self.requestedLocalPort
                                                                count:&_localAddressesSockaddrCount /* returns struct sockaddr data in NSData */
                                                         socketFamily:AF_INET6];
    }
}

- (UMSocketError) bind
{
    NSMutableArray *useable_local_addr = [[NSMutableArray alloc]init];

    if((_localAddressesSockaddr==NULL) || ( _localAddressesSockaddrCount==0))
    {
        _localAddressesSockaddr = [UMSocketSCTP sockaddrFromAddresses:_requestedLocalAddresses
                                                                 port:self.requestedLocalPort
                                                                count:&_localAddressesSockaddrCount /* returns struct sockaddr data in NSData */
                                                         socketFamily:_socketFamily];
    }
    /* at this point usable_addresses contains strings which are in _socketFamily specific formats */
    /* invalid IP's have been remvoed */
    int usable_ips = -1;

    for(int i=0;i<_localAddressesSockaddrCount;i++)
    {
        struct sockaddr *localAddress = NULL;
        if(_socketFamily == AF_INET6)
        {
            struct sockaddr_in6 *local_addresses=(struct sockaddr_in6 *)_localAddressesSockaddr.bytes;
            localAddress = (struct sockaddr *)&local_addresses[i];
        }
        else
        {
            struct sockaddr_in *local_addresses=(struct sockaddr_in *)_localAddressesSockaddr.bytes;
            localAddress = (struct sockaddr *)&local_addresses[i];
        }
        NSString *addr = [UMSocket addressOfSockAddr:localAddress];
        if(usable_ips == -1)
        {
#if defined(ULIBSCTP_CONFIG_DEBUG)
            int port = [UMSocket portOfSockAddr:localAddress];
            NSLog(@"calling bind for '%@:%d' on socket %d",addr,port,_sock);
#endif
            int err;
            if(_socketFamily == AF_INET6)
            {
                err = bind(_sock, localAddress,sizeof(struct sockaddr_in6));
            }
            else
            {
                err = bind(_sock, localAddress,sizeof(struct sockaddr_in));
            }
            if(err==0)
            {
#if defined(ULIBSCTP_CONFIG_DEBUG)
                NSLog(@" bind succeeds for %@:%d",addr,_requestedLocalPort);
#endif
                usable_ips = 1;
                [useable_local_addr addObject:addr];
            }
            else
            {
                NSLog(@" bind returns error %d %s for %@",errno,strerror(errno),addr);
            }
        }
        else
        {
#if defined(ULIBSCTP_CONFIG_DEBUG)
            int port = [UMSocket portOfSockAddr:localAddress];
            NSLog(@"calling sctp_bindx for '%@:%d'",addr,port);
#endif
            int err = [self bindx:localAddress];
            if(err==0)
            {
#if defined(ULIBSCTP_CONFIG_DEBUG)
                NSLog(@" sctp_bindx succeeds for %@",addr);
#endif
                usable_ips++;
                [useable_local_addr addObject:addr];
            }
            else
            {
                NSLog(@" sctp_bindx returns error %d %s for %@",errno,strerror(errno),addr);
            }
        }
    }
    if(usable_ips <= 0)
    {
        [_historyLog addLogEntry:@"bind: no usable IPs"];
#if defined(ULIBSCTP_CONFIG_DEBUG)
        NSLog(@"bind(SCTP): usable_ips=%d",usable_ips);
#endif
        return UMSocketError_address_not_available;
    }
    else
    {
        NSString *s = [useable_local_addr componentsJoinedByString:@","];
        s = [NSString stringWithFormat:@"bind: %@",s];
        [_historyLog addLogEntry:s];
    }
    _useableLocalAddresses = useable_local_addr;
    return UMSocketError_no_error;
}

- (UMSocketError) enableEvents
{
#if !defined(HAS_SCTP)
    return UMSocketError_not_supported_operation;
#else
    struct sctp_event_subscribe event;
    
    /**********************/
    /* ENABLING EVENTS    */
    /**********************/

    [_historyLog addLogEntry:@"enableEvents"];
    memset((void *)&event,0x00, sizeof(struct sctp_event_subscribe));
    event.sctp_data_io_event            = 1;
    event.sctp_association_event        = 1;
    event.sctp_address_event            = 1;
    event.sctp_send_failure_event       = 1;
    event.sctp_peer_error_event         = 1;
    event.sctp_shutdown_event           = 1;
    event.sctp_partial_delivery_event   = 1;
    event.sctp_adaptation_layer_event   = 1;
//    event.sctp_authentication_event     = 1;
#ifndef LINUX
    event.sctp_stream_reset_events      = 1;
#endif
    if(setsockopt(_sock, IPPROTO_SCTP, SCTP_EVENTS, &event, sizeof(event)) != 0)
    {
        return [UMSocket umerrFromErrno:errno];
    }
    return UMSocketError_no_error;
#endif
}

- (int)mtu
{
    return _mtu;
}


- (int)currentMtu
{
#if !defined(HAS_SCTP)
    return 0;
#else
   int readMtu = 0;
    struct sctp_paddrparams params;
    socklen_t len = sizeof(params);
    memset((void *)&params,0x00, sizeof(struct sctp_paddrparams));

    if(getsockopt(_sock, IPPROTO_SCTP, SCTP_PEER_ADDR_PARAMS, &params, &len) == 0)
    {
        readMtu = params.spp_pathmtu;
    }
    return readMtu;
#endif
}

- (void)setMtu:(int)newMtu
{
    [self configureMtu:newMtu];
}

- (UMSocketError)configureMtu:(int)newMtu
{
#if !defined(HAS_SCTP)
    return UMSocketError_not_supported_operation;
#else

    UMSocketError err = UMSocketError_no_error;
    [_historyLog addLogEntry:[NSString stringWithFormat:@"setMtu:%d",newMtu]];
    _mtu = newMtu;
    struct sctp_paddrparams params;
    socklen_t len = sizeof(params);

    memset((void *)&params,0x00, sizeof(struct sctp_paddrparams));
    if(getsockopt(_sock, IPPROTO_SCTP, SCTP_PEER_ADDR_PARAMS, &params, &len) == 0)
    {
        if(newMtu > 0)
        {
            params.spp_pathmtu = newMtu;
        }
        else
        {
            params.spp_pathmtu = 0;
        }
        if(setsockopt(_sock, IPPROTO_SCTP, SCTP_PEER_ADDR_PARAMS, &params, len) == 0)
        {
            if(getsockopt(_sock, IPPROTO_SCTP, SCTP_PEER_ADDR_PARAMS, &params, &len) == 0)
            {
                if(params.spp_flags & SPP_PMTUD_DISABLE)
                {
                    _mtu = params.spp_pathmtu;
                }
                else
                {
                    _mtu = 0;
                }
            }
            else
            {
                err = [UMSocket umerrFromErrno:errno];
            }
        }
        else
        {
            err = [UMSocket umerrFromErrno:errno];
        }
    }
    return err;
#endif
}

- (UMSocketError)setPathMtuDiscovery:(BOOL)enable
{
#if !defined(HAS_SCTP)
    return UMSocketError_not_supported_operation;
#else

    [_historyLog addLogEntry:[NSString stringWithFormat:@"setPathMtuDiscovery:%@",enable ? @"YES" : @"NO"]];
    struct sctp_paddrparams params;
    socklen_t len = sizeof(params);
    memset((void *)&params,0x00, sizeof(struct sctp_paddrparams));
    
    UMSocketError err = [super setPathMtuDiscovery:enable];
    if(getsockopt(_sock, IPPROTO_SCTP, SCTP_PEER_ADDR_PARAMS, &params, &len) == 0)
    {
        if(enable)
        {
            params.spp_flags &= ~SPP_PMTUD_DISABLE;
            params.spp_flags |= SPP_PMTUD_ENABLE;
        }
        else
        {
            params.spp_flags &= ~SPP_PMTUD_ENABLE;
            params.spp_flags |= SPP_PMTUD_DISABLE;
        }
        if(setsockopt(_sock, IPPROTO_SCTP, SCTP_PEER_ADDR_PARAMS, &params, len) == 0)
        {
            _pathMtuDiscovery = enable;
            err = UMSocketError_no_error;
        }
        else
        {
            err = [UMSocket umerrFromErrno:errno];
        }
    }
    return err;
#endif
}

- (BOOL) isPathMtuDiscoveryEnabled
{
#if !defined(HAS_SCTP)
    return NO;
#else

    struct sctp_paddrparams params;
    socklen_t len = sizeof(params);
    memset((void *)&params,0x00, sizeof(struct sctp_paddrparams));
    if(getsockopt(_sock, IPPROTO_SCTP, SCTP_PEER_ADDR_PARAMS, &params, &len) == 0)
    {
        if(params.spp_flags & SPP_PMTUD_ENABLE)
        {
            return YES;
        }
        if(params.spp_flags & SPP_PMTUD_DISABLE)
        {
            return NO;
        }
    }
    return _pathMtuDiscovery;
#endif
    
}

- (UMSocketError)setHeartbeat:(BOOL)enable
{
#if !defined(HAS_SCTP)
    return UMSocketError_not_supported_operation;
#else

    if(enable)
    {
        [_historyLog addLogEntry:@"enable heartbeat"];
    }
    else
    {
        [_historyLog addLogEntry:@"disable heartbeat"];
    }
    struct sctp_paddrparams heartbeat;
    socklen_t len = sizeof(heartbeat);

    memset((void *)&heartbeat,0x00, sizeof(struct sctp_paddrparams));
    if(getsockopt(_sock, IPPROTO_SCTP, SCTP_PEER_ADDR_PARAMS, &heartbeat, &len) == 0)
    {
        if(_socketFamily == AF_INET)
        {
            struct sockaddr_in *sa = (struct sockaddr_in *)&heartbeat.spp_address;
            memset(sa,0x00,sizeof(struct sockaddr_in));
            sa->sin_family = AF_INET;
#ifdef    HAS_SOCKADDR_LEN
            sa->sin_len = sizeof(struct sockaddr_in);
#endif
            sa->sin_addr.s_addr = htonl(INADDR_ANY);
        }
        else if(_socketFamily == AF_INET6)
        {
            struct sockaddr_in6 *sa6 = (struct sockaddr_in6 *)&heartbeat.spp_address;
            memset(sa6,0x00,sizeof(struct sockaddr_in6));
            sa6->sin6_family = AF_INET6;
#ifdef    HAS_SOCKADDR_LEN
            sa6->sin6_len = sizeof(struct sockaddr_in6);
#endif
            sa6->sin6_addr = in6addr_any;
        }
        if(enable)
        {
            heartbeat.spp_flags = SPP_HB_ENABLE;
            heartbeat.spp_hbinterval = 30000;
            heartbeat.spp_pathmaxrxt = 1;
        }
        else
        {
            heartbeat.spp_flags = SPP_HB_DISABLE;
            heartbeat.spp_hbinterval = 30000;
            heartbeat.spp_pathmaxrxt = 1;
        }
        if(setsockopt(_sock, IPPROTO_SCTP, SCTP_PEER_ADDR_PARAMS , &heartbeat, sizeof(heartbeat)) != 0)
        {
            return [UMSocket umerrFromErrno:errno];
        }
        return UMSocketError_no_error;
    }
    if(errno)
    {
        [_historyLog addLogEntry:[NSString stringWithFormat:@"errno=%d %s",errno,strerror(errno)]];
    }
    return [UMSocket umerrFromErrno:errno];
#endif
}


- (int)maxSegment
{
    return _maxSeg;
}

- (void)setMaxSegment:(int)newMaxSeg
{
#if !defined(HAS_SCTP)
    return;
#else

    int disableFragments = 0;
    if(newMaxSeg > 0)
    {
        disableFragments = 1;
    }
    setsockopt(_sock,IPPROTO_SCTP,SCTP_DISABLE_FRAGMENTS, &disableFragments, sizeof(int));
    setsockopt(_sock,IPPROTO_SCTP,SCTP_MAXSEG, &newMaxSeg, sizeof(int));
    
    [_historyLog addLogEntry:[NSString stringWithFormat:@"setMaxSegment %d errno=%d %s",newMaxSeg,errno,strerror(errno)]];

    _maxSeg = newMaxSeg;
#endif
}

- (UMSocketError)updateMtu:(int)newMtu
{

/* to mitigate kernel panic in some versions
     https://www.spinics.net/lists/netdev/msg534371.html
*/
    UMSocketError err = UMSocketError_no_error;
    if(newMtu==0)
    {
        [self configureMtu:1500];
        err = [self configureMtu:0];
    }
    else
    {
        [self configureMtu:0];
        err = [self configureMtu:newMtu];
    }
    return err;
}

- (UMSocketError) enableFutureAssoc
{
#if !defined(HAS_SCTP)
    return UMSocketError_not_supported_operation;
#else

    UMSocketError r = UMSocketError_no_error;

#if defined(SCTP_FUTURE_ASSOC) && defined(SCTP_ADAPTATION_INDICATION)
    struct sctp_event event;
    /* Enable the events of interest. */
    memset(&event, 0, sizeof(event));
    event.se_assoc_id = SCTP_FUTURE_ASSOC;
    event.se_on = 1;
    event.se_type = SCTP_ADAPTATION_INDICATION;
    if (setsockopt(_sock, IPPROTO_SCTP, SCTP_EVENT, &event, sizeof(event)) < 0)
    {
        r = [UMSocket umerrFromErrno:errno];
    }
    [_historyLog addLogEntry:[NSString stringWithFormat:@"enableFutureAssoc: errno=%d %s",errno,strerror(errno)]];
#endif
    return r;
#endif
}



+ (NSData *)sockaddrFromAddresses:(NSArray *)theAddrs
                             port:(int)thePort
                            count:(int *)count_out /* returns struct sockaddr data in NSData */
                     socketFamily:(int)socketFamily
{
    struct sockaddr_in6 *addresses6=NULL;
    struct sockaddr_in  *addresses4=NULL;
    struct sockaddr     *addresses46 = NULL;
    size_t              addresses46_len = 0;

    int count = (int)theAddrs.count;

    int j=0;
    if(socketFamily==AF_INET6)
    {
        addresses6 = calloc(count,sizeof(struct sockaddr_in6));
        for(int i=0;i<count;i++)
        {
            NSString *address = [theAddrs objectAtIndex:i];
            NSString *address2 = [UMSocket deunifyIp:address];
            if([address2 isEqualToString:@"localost"])
            {
                address2 = @"127.0.0.1";
            }
            if(address2.length>0)
            {
                address = address2;
            }
            if([address isIPv4])
            {
                /* we have a IPV6 socket but the remote addres is in IPV4 format so we must use the IPv6 representation of it */
                address =[NSString stringWithFormat:@"::ffff:%@",address];
            }
            int result = inet_pton(AF_INET6,address.UTF8String, &addresses6[j].sin6_addr);
            if(result==1)
            {
#ifdef HAVE_SOCKADDR_SIN_LEN
                addresses6[j].sin6_len = sizeof(struct sockaddr_in6);
#endif
                addresses6[j].sin6_family = AF_INET6;
                addresses6[j].sin6_port = htons(thePort);
                j++;
            }
            else
            {
                NSLog(@"%@ is not a valid IP address. skipped ",address);
            }
        }
        if(j==0)
        {
            NSLog(@"no valid local IP addresses found %@:%d AF_INET6",[theAddrs componentsJoinedByString:@","],thePort);
            free(addresses6);
            addresses6 = NULL;
            *count_out = 0;
        }
        else
        {
            if(j<count)
            {
                addresses6 = realloc(addresses6,sizeof(struct sockaddr_in6)*j);
                count = j;
            }
            addresses46 = (struct sockaddr *)addresses6;
            addresses46_len = sizeof(struct sockaddr_in6)*count;
        }
    }
    else if(socketFamily==AF_INET)
    {
        addresses4 = calloc(count,sizeof(struct sockaddr_in));
        for(int i=0;i<count;i++)
        {
            NSString *address = [theAddrs objectAtIndex:i];
            NSString *address2 = [UMSocket deunifyIp:address];
            if(address2.length>0)
            {
                address = address2;
            }
            int result = inet_pton(AF_INET,address.UTF8String, &addresses4[j].sin_addr);
            if(result==1)
            {
#ifdef HAVE_SOCKADDR_SIN_LEN
                addresses4[j].sin_len = sizeof(struct sockaddr_in);
#endif
                addresses4[j].sin_family = AF_INET;
                addresses4[j].sin_port = htons(thePort);
                j++;
            }
            else
            {
                NSLog(@"'%@' is not a valid IP address. skipped ",address);
            }
        }
        if(j==0)
        {
            NSLog(@"no valid local IP addresses found %@:%d AF_INET",[theAddrs componentsJoinedByString:@","],thePort);
            free(addresses4);
        }
        else
        {
            if(j<count)
            {
                addresses4 = realloc(addresses4,sizeof(struct sockaddr_in)*j);
                count = j;
            }
            addresses46 = (struct sockaddr *)addresses4;
            addresses46_len = sizeof(struct sockaddr_in)*count;
        }
    }
    if(count_out)
    {
        *count_out = count;
    }
    NSData *result = [NSData dataWithBytes:addresses46 length:addresses46_len];
    free(addresses46);
    return result;
}

- (UMSocketError) connect
{
    NSNumber *assoc = NULL;

    UMSocketError e = [self connectToAddresses:_requestedRemoteAddresses
                        port:_requestedRemotePort
                    assocPtr:&assoc
                       layer:NULL];
    return e;
}

- (UMSocketError) connectAssocPtr:(NSNumber **)assoc;
{
    UMSocketError e = [self connectToAddresses:_requestedRemoteAddresses
                                          port:_requestedRemotePort
                                      assocPtr:assoc
                                         layer:NULL];
    return e;
}

- (UMSocketError) connectToAddresses:(NSArray *)addrs
                                port:(int)remotePort
                            assocPtr:(NSNumber **)assocptr
                               layer:(UMLayer *)layer
{
	UMAssert(assocptr!=NULL,@"assocptr can not be NULL");
#if !defined(HAS_SCTP)
    return UMSocketError_not_supported_operation;
#else

    sctp_assoc_t tmp_assoc = -2;

    int count = 0;
    NSData *remote_sockaddr = [UMSocketSCTP sockaddrFromAddresses:addrs port:remotePort count:&count socketFamily:_socketFamily]; /* returns struct sockaddr data in NSData */

    /**********************/
    /* CONNECTX           */
    /**********************/
    UMSocketError returnValue = UMSocketError_no_error;

    if(count<1)
    {
        self.status = UMSOCKET_STATUS_OFF;
        returnValue = UMSocketError_address_not_available;
    }
    else
    {
#if defined(ULIBSCTP_CONFIG_DEBUG)
        NSLog(@"calling sctp_connectx (%@)", [addrs componentsJoinedByString:@" "]);
#endif
        
        
        int err =  sctp_connectx(_sock,(struct sockaddr *)remote_sockaddr.bytes,count,&tmp_assoc);
#if defined(ULIBSCTP_CONFIG_DEBUG)
        if((tmp_assoc != -2) && (err==0))
        {
            *assocptr = @(tmp_assoc);
        }
        NSLog(@"sctp_connectx: returns %d. errno = %d %s assoc=%lu",err,errno,strerror(errno),(unsigned long)tmp_assoc);
#endif
        _connectedRemotePort = remotePort;

        if (err < 0)
        {
            returnValue = [UMSocket umerrFromErrno:errno];
            if(returnValue==UMSocketError_is_already_connected)
            {
                self.status = UMSOCKET_STATUS_OOS;
                self.status = UMSOCKET_STATUS_IS;
                self.isConnecting=NO;
                self.isConnected=YES;
            }
			else if(   (returnValue==UMSocketError_in_progress)
                    || (returnValue==UMSocketError_busy)) /* if we have a incoming connection we might get EBUSY */
			{
				_connectx_pending = YES;
                self.status = UMSOCKET_STATUS_OOS;
                self.isConnecting=YES;
                self.isConnected=NO;
			}
        }
        else
        {
            _connectx_pending = YES;
            self.status = UMSOCKET_STATUS_IS;
            returnValue = UMSocketError_no_error;
            self.isConnected=YES;
        }
    }
    
    [_historyLog addLogEntry:[NSString stringWithFormat:@"connect(%@:%d) assoc=%@ %@",
                           [addrs componentsJoinedByString:@","],
                           remotePort,
                           *assocptr,
                           [UMSocket getSocketErrorString:returnValue]]];
    return returnValue;
#endif
}

/* overloading accept */
- (UMSocketSCTP *) accept:(UMSocketError *)ret
{
    return [self acceptSCTP:ret];
}

- (UMSocketSCTP *) acceptSCTP:(UMSocketError *)ret
{
    int           newsock = -1;
    UMSocketSCTP  *newcon =NULL;
    NSString *remoteAddress=@"";
    in_port_t remotePort=0;
    if(_type == UMSOCKET_TYPE_SCTP4ONLY_SEQPACKET)
    {
        struct    sockaddr_in sa4;
        socklen_t slen4 = sizeof(sa4);
        ummutex_lock(_controlLock);
        newsock = accept(_sock,(struct sockaddr *)&sa4,&slen4);
        ummutex_unlock(_controlLock);

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
        struct    sockaddr_in6        sa6;
        socklen_t slen6 = sizeof(sa6);
        memset(&sa6,0x00,slen6);
        sa6.sin6_port = htons(3868);
        ummutex_lock(_controlLock);
        newsock = accept(_sock,(struct sockaddr *)&sa6,&slen6);
        ummutex_unlock(_controlLock);

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
        NSString *name = [NSString stringWithFormat:@"accept(%@)",_socketName];
        newcon = [[UMSocketSCTP alloc]initWithType:_type name:name existingSocket:newsock];
        newcon.socketFamily = self.socketFamily;
        newcon.direction =  _direction;
        newcon.status=UMSOCKET_STATUS_IS;
        newcon.localHost = self.localHost;
        newcon.remoteHost = self.remoteHost;
        newcon.requestedLocalAddresses = _requestedLocalAddresses;
        newcon.requestedLocalPort=self.requestedLocalPort;
        newcon.requestedRemoteAddresses = _requestedRemoteAddresses;
        newcon.requestedRemotePort=self.requestedRemotePort;

		newcon.connectedLocalAddresses = _connectedLocalAddresses;
		newcon.connectedLocalPort=self.connectedLocalPort;
		newcon.connectedRemoteAddresses = _connectedRemoteAddresses;
		newcon.connectedRemotePort=self.connectedRemotePort;
        newcon.cryptoStream = [[UMCrypto alloc]initWithRelatedSocket:newcon];
        newcon.cryptoStream.fileDescriptor = newsock;
        newcon.isBound=NO;
        newcon.isListening=NO;
        newcon.isConnecting=NO;
        newcon.isConnected=YES;
        [newcon setSock: newsock];
        [newcon switchToNonBlocking];
        [newcon doInitReceiveBuffer];
        [newcon setPathMtuDiscovery:YES];
        newcon.connectedRemoteAddress = remoteAddress;
        newcon.connectedRemotePort = remotePort;
        newcon.useSSL = _useSSL;
        [newcon updateMtu:_mtu];
        [newcon updateName];
        newcon.objectStatisticsName = @"UMSocket(accept)";
        newcon.historyLog = [[UMHistoryLog alloc]initWithMaxLines:100];
        [self reportStatus:@"accept () successful"];
        /* TODO: start SSL if required here */
        *ret = UMSocketError_no_error;
        return newcon;
    }
    *ret = [UMSocket umerrFromErrno:errno];
    return nil;
}

- (UMSocketSCTP *) peelOffAssoc:(NSNumber *)assoc
                          error:(UMSocketError *)errptr
                    errorNumber:(int *)e
{
#if !defined(HAS_SCTP)
    if(errptr)
    {
        *errptr = UMSocketError_not_supported_operation;
    }
    return NULL;
#else

    if(assoc==NULL)
    {
        if(errptr)
        {
            *errptr = UMSocketError_not_existing;
        }
        return NULL;
    }
    if(assoc.unsignedLongValue == 0)
    {
        if(errptr)
        {
            *errptr = UMSocketError_not_a_socket;
        }
        return NULL;
    }
#if defined(ULIBSCTP_CONFIG_DEBUG)
    NSLog(@"calling peelOffAssoc:(assoc=%@)",assoc);
#endif
    int           newsock = -1;
    UMSocketSCTP  *newcon =NULL;
    NSString *remoteAddress=@"";
    in_port_t remotePort=0;
    
    ummutex_lock(_controlLock);
    sctp_assoc_t a = (sctp_assoc_t)assoc.unsignedLongValue;
    newsock = sctp_peeloff(_sock,a);
    NSLog(@"sctp_peeloff(_sock=%d,_assoc=%d) returns %d",_sock,a,newsock);
    ummutex_unlock(_controlLock);

    if(newsock >=0)
    {
        if(_type == UMSOCKET_TYPE_SCTP4ONLY_SEQPACKET)
        {
            struct    sockaddr_in sa4;
            socklen_t slen4 = sizeof(sa4);
            memset(&sa4,0x00,slen4);
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
            }
        }
        else
        {
            /* IPv6 or dual mode */
            struct    sockaddr_in6        sa6;
            socklen_t slen6 = sizeof(sa6);
            memset(&sa6,0x00,slen6);
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
            }
        }
        TRACK_FILE_SOCKET(newsock,remoteAddress);
        NSString *name = [NSString stringWithFormat:@"peeloff(%@)",_socketName];
        newcon = [[UMSocketSCTP alloc]initWithType:_type name:name existingSocket:newsock];
        newcon.isBound=NO;
        newcon.isListening=NO;
        newcon.isConnecting=NO;
        newcon.isConnected=YES;
        newcon.type = _type;
        newcon.socketDomain = _socketDomain;
        newcon.socketFamily = _socketFamily;
        newcon.socketType = _socketType;
        newcon.socketProto = _socketProto;
        newcon.xassoc = assoc;
        newcon.direction =  _direction;
        newcon.status= _status;
        newcon.localHost = self.localHost;
        newcon.remoteHost = self.remoteHost;
        newcon.requestedLocalAddresses = _requestedLocalAddresses;
        newcon.requestedLocalPort=self.requestedLocalPort;
        newcon.requestedRemoteAddresses = _requestedRemoteAddresses;
        newcon.requestedRemotePort=self.requestedRemotePort;
        newcon.connectedLocalAddresses = _connectedLocalAddresses;
        newcon.connectedLocalPort=self.connectedLocalPort;
        newcon.connectedRemoteAddress = remoteAddress;
        newcon.connectedRemotePort = remotePort;
        newcon.cryptoStream = [[UMCrypto alloc]initWithRelatedSocket:newcon];
        [newcon switchToNonBlocking];
        [newcon doInitReceiveBuffer];
        [newcon setPathMtuDiscovery:YES];
        newcon.useSSL = _useSSL;
        [newcon updateMtu:_mtu];
        [newcon updateName];
        newcon.objectStatisticsName = @"UMSocket(peeloff)";
        newcon.historyLog = [[UMHistoryLog alloc]initWithMaxLines:100];
		newcon.configuredMaxSegmentSize = _configuredMaxSegmentSize;
		int activeSctpMaxSegmentSize = 0;

        struct sctp_assoc_value a;
        a.assoc_id = [assoc unsignedIntValue];
        a.assoc_value = 0;

        socklen_t maxseg_len = sizeof(a);

		if(getsockopt(_sock, IPPROTO_SCTP, SCTP_MAXSEG, &a, &maxseg_len) == 0)
		{
			newcon.activeMaxSegmentSize = a.assoc_value;
			if((_configuredMaxSegmentSize > 0) && (_configuredMaxSegmentSize < activeSctpMaxSegmentSize))
			{
                newcon.activeMaxSegmentSize = _configuredMaxSegmentSize;
				if(setsockopt(_sock, IPPROTO_SCTP, SCTP_MAXSEG, &activeSctpMaxSegmentSize, maxseg_len))
				{
                    if(getsockopt(_sock, IPPROTO_SCTP, SCTP_MAXSEG, &a, &maxseg_len) == 0)
                    {
                        newcon.activeMaxSegmentSize = a.assoc_value;
                    }
				}
			}
		}
        newcon.direction =  _direction;
        newcon.status=_status;
        newcon.localHost = self.localHost;
        newcon.remoteHost = self.remoteHost;
        newcon.requestedLocalAddresses = _requestedLocalAddresses;
        newcon.requestedLocalPort=_requestedLocalPort;
        newcon.requestedRemoteAddresses = _requestedRemoteAddresses;
        newcon.requestedRemotePort=_requestedRemotePort;
		newcon.connectedLocalAddresses = _connectedLocalAddresses;
		newcon.connectedLocalPort = _connectedLocalPort;
		newcon.connectedRemoteAddresses = @[remoteAddress];
		newcon.connectedRemotePort = remotePort;
        newcon.cryptoStream = [[UMCrypto alloc]initWithRelatedSocket:newcon];
        newcon.cryptoStream.fileDescriptor = newsock;
        newcon.isBound=NO;
        newcon.isListening=NO;
        newcon.isConnecting=NO;
        newcon.isConnected=YES;
        [newcon setSock: newsock];
        [newcon switchToNonBlocking];
        [newcon doInitReceiveBuffer];
        newcon.useSSL = _useSSL;
        [newcon updateMtu:_mtu];
        [newcon updateName];
        newcon.objectStatisticsName = @"UMSocket(accept)";
        [self reportStatus:@"peeloff () successful"];
        /* TODO: start SSL if required here */
        if(errptr)
        {
            *errptr = UMSocketError_no_error;
        }
#if defined(ULIBSCTP_CONFIG_DEBUG)
        NSLog(@"   returning new socket/UMSocketError_no_error");
#endif
        return newcon;
    }
    /* sctp_peeloff returned error */
    int e2 = errno;
    if(e)
    {
        *e = e2;
    }
    UMSocketError ee = [UMSocket umerrFromErrno:e2];
    if(errptr)
    {
        *errptr = ee;
    }

#if defined(ULIBSCTP_CONFIG_DEBUG)
    NSLog(@"   returning nil/err = %@ (errno=%d)",[UMSocket getSocketErrorString:e],errno);
#endif
    return nil;
#endif
}

- (ssize_t) sendToAddresses:(NSArray *)addrs
                       port:(int)remotePort
                   assocPtr:(NSNumber **)assocptr
                       data:(NSData *)data
                     stream:(NSNumber *)streamId
                   protocol:(NSNumber *)protocolId
                      error:(UMSocketError *)err2
{
#if !defined(HAS_SCTP)
    if(err2)
    {
        *err2 = UMSocketError_not_supported_operation;
    }
    return 0;
#else

    int flags = 0;
    int timetolive = 0;
    int context = 0;

	UMAssert(assocptr!=NULL,@"assocptr can not be NULL");
    UMSocketError err = UMSocketError_no_error;

    ssize_t sp = 0;
    if(data == NULL)
    {
        if(err2)
        {
            *err2 = UMSocketError_no_data;
        }
        return -1;
    }

    if(self.isConnected==NO)
    {
        err = [self connectToAddresses:addrs
                                  port:remotePort
                              assocPtr:assocptr
                                 layer:NULL];
        if((err == UMSocketError_is_already_connected) || (err==UMSocketError_in_progress))
        {
            err = UMSocketError_no_error;
            if(err2)
            {
                *err2 =err;
            }
        }
        else
        {
            if(err2)
            {
                *err2 = err;
            }
            return -1;
        }
    }
	int count = 0;

	NSData *remote_sockaddr = [UMSocketSCTP sockaddrFromAddresses:addrs port:remotePort count:&count socketFamily:_socketFamily]; /* returns struct sockaddr data in NSData */
#if defined(ULIBSCTP_CONFIG_DEBUG)
	NSMutableString *s = [[NSMutableString alloc]init];

	[s appendFormat:@"sctp_sendmsg(_sock=%d,\n",_sock];
	[s appendFormat:@"\tdata.bytes=%p\n",(void *)data.bytes];
	[s appendFormat:@"\tdata.length=%ld\n",(long)data.length];
	[s appendFormat:@"\t(struct sockaddr *)remote_sockaddr.bytes=%p\n",remote_sockaddr.bytes];
	[s appendFormat:@"\t(socklen_t)remote_sockaddr.length=%ld\n",(long)remote_sockaddr.length];
	[s appendFormat:@"\tprotocolId=%ld\n",(long)protocolId];
	[s appendFormat:@"\tflags=%ld\n",(long)flags];
    [s appendFormat:@"\tstreamId=%ld\n",(long)streamId];
	[s appendFormat:@"\ttimetolive=%ld\n",(long)timetolive];
	[s appendFormat:@"\tcontext=%ld\n",(long)context];
	[s appendFormat:@"\tassoc=%ld\n",(long)*assocptr];
	[s appendFormat:@"\tremote Addresses: %@\n",[addrs componentsJoinedByString:@","]];
	[s appendFormat:@"\tremote Port: %ld\n",(long)remotePort];
	if(self.logFeed)
	{
		[self.logFeed debugText:s];
	}
	else
	{
		NSLog(@"%@",s);
	}
#endif
    ummutex_lock(_dataLock);
    sp = sctp_sendmsg(_sock,
                      (const void *)data.bytes,
                      data.length,
                      (struct sockaddr *)remote_sockaddr.bytes,
                      (socklen_t)remote_sockaddr.length,
                      htonl(protocolId.unsignedLongValue),
                      flags, /* flags */
                      streamId.unsignedIntValue,
                      timetolive, // timetolive,
                      context); // context);
    ummutex_unlock(_dataLock);
    if(sp<0)
    {
#if defined(ULIBSCTP_CONFIG_DEBUG)
		NSString *s = [NSString stringWithFormat:@"errno: %d %s",errno, strerror(errno)];
		[self.logFeed debugText:s];
#endif

        err = [UMSocket umerrFromErrno:errno];
    }
    else if(sp==0)
    {
        err = UMSocketError_no_data;
    }
    if(err2)
    {
        *err2 = err;
    }
    return sp;
#endif
}



- (UMSocketError) abortToAddress:(NSString *)addr
                            port:(int)remotePort
                           assoc:(NSNumber *)assoc
                          stream:(NSNumber *)streamId
                        protocol:(NSNumber *)protocolId
{
#if !defined(HAS_SCTP)
    return UMSocketError_not_supported_operation;
#else

    UMSocketError err = UMSocketError_no_error;
    ssize_t sp = 0;
    int count = 0;
    NSArray *addrs = @[addr];
    NSData *remote_sockaddr = [UMSocketSCTP sockaddrFromAddresses:addrs port:remotePort count:&count socketFamily:_socketFamily]; /* returns struct sockaddr data in NSData */
    int flags = SCTP_ABORT;

    uint32_t timetolive=8000;
    uint32_t context=0;

#if defined(ULIBSCTP_CONFIG_DEBUG)
    NSLog(@"sctp_sendmsg(_sock=%d,\n\tdata.bytes=NULL\n\tdata.length=0\n\t(struct sockaddr *)remote_sockaddr.bytes=%p\n\t(socklen_t)remote_sockaddr.length=%ld\n\tprotocolId=%lu\n\tflags=%ld\n\tstreamId=%lu\n\ttimetolive=%ld\n\tcontext=%ld\n);\n",
          (int)_sock,
          remote_sockaddr.bytes,
          (long)remote_sockaddr.length,
          protocolId.unsignedLongValue,
          (long)flags, /* flags */
          streamId.unsignedLongValue,
          (long)timetolive, // timetolive,
          (long)context); // context);
#endif

    sp = sctp_sendmsg(_sock,
                      NULL,
                      0,
                      (struct sockaddr *)remote_sockaddr.bytes,
                      (socklen_t)remote_sockaddr.length,
                      htonl(protocolId.unsignedLongValue),
                      flags, /* flags */
                      streamId.unsignedShortValue,
                      timetolive, // timetolive,
                      context); // context);
    if(sp<0)
    {
        int e = errno;
#if defined(ULIBSCTP_CONFIG_DEBUG)
        NSLog(@"errno: %d %s",e, strerror(e));
#endif

        err = [UMSocket umerrFromErrno:e];
    }
    else if(sp==0)
    {
        err = UMSocketError_no_error;
    }
    return err;
#endif
}


#define SCTP_RXBUF 10240

- (UMSocketSCTPReceivedPacket *)receiveSCTP
{
#if !defined(HAS_SCTP)
    return NULL;
#else

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
    char                    buffer[SCTP_RXBUF+1];
    int                     flags=0;

    memset(&buffer[0],0xFA,sizeof(buffer));
    memset(remote_address_ptr,0x00,sizeof(remote_address_len));
    int rxerr;
    UMSocketSCTPReceivedPacket *rx = [[UMSocketSCTPReceivedPacket alloc]init];
    struct sctp_sndrcvinfo sinfo;
    do
    {
        rxerr = 0;
        memset(&sinfo,0x00,sizeof(sinfo));
        bytes_read = sctp_recvmsg(_sock,
                                  &buffer,
                                  SCTP_RXBUF,
                                  remote_address_ptr,
                                  &remote_address_len,
                                  &sinfo,
                                  &flags);
        if(bytes_read <= 0)
        {
#if defined(ULIBSCTP_CONFIG_DEBUG)
            NSLog(@"errno %d %s",errno,strerror(errno));
#endif
            rxerr = errno;
            rx.err = [UMSocket umerrFromErrno:rxerr];
        }
    } while(rxerr==EAGAIN);
    
    if(bytes_read > 0)
    {
        rx.remoteAddress = [UMSocket addressOfSockAddr:remote_address_ptr];
        rx.remotePort = [UMSocket portOfSockAddr:remote_address_ptr];
        rx.data = [NSData dataWithBytes:&buffer length:bytes_read];
        rx.flags = flags;
        if(flags & MSG_NOTIFICATION)
        {
            rx.isNotification = YES;
        }
        else
        {
            rx.streamId = @(sinfo.sinfo_stream);
            rx.protocolId = @(ntohl(sinfo.sinfo_ppid));
            rx.context = @(sinfo.sinfo_context);
            rx.assocId = @(sinfo.sinfo_assoc_id);
        }
        rx.socket = @(_sock);
    }
    return rx;
#endif
    
}

- (UMSocketError)close
{
    _dataDelegate = NULL;
    _notificationDelegate = NULL;
    self.status = UMSOCKET_STATUS_OFF;
    return [super close];
}


- (UMSocketError) dataIsAvailableSCTP:(int)timeoutInMs
                            dataAvail:(int *)hasData
                               hangup:(int *)hasHup
{
    UMSocketError returnValue = UMSocketError_no_data;
    struct pollfd pollfds[1];
    int ret1;
    int ret2;
    int eno = 0;

    int events = POLLIN | POLLPRI | POLLERR | POLLHUP | POLLNVAL;
        
    memset(pollfds,0,sizeof(pollfds));
    pollfds[0].fd = _sock;
    pollfds[0].events = events;
    
    //    UMAssert(timeoutInMs>0,@"timeout should be larger than 0");
    UMAssert(timeoutInMs<200000,@"timeout should be smaller than 20seconds");
    
#if defined(ULIBSCTP_CONFIG_DEBUG)
    NSLog(@"calling poll (timeout =%dms,socket=%d)",timeoutInMs,_sock);
#endif

    ummutex_lock(_controlLock);
    ret1 = poll(pollfds, 1, timeoutInMs);
    ummutex_unlock(_controlLock);


    if (ret1 < 0)
    {
        eno = errno;
        if((eno==EINPROGRESS) || (eno == EINTR) || (eno==EAGAIN) || (eno==EBUSY))
        {
            returnValue = UMSocketError_no_data;
        }
        else
        {
            returnValue = [UMSocket umerrFromErrno:eno];
        }
    }
    else if (ret1 == 0)
    {
        returnValue = UMSocketError_no_data;
    }
    else /* ret1 > 0 */
    {
        /* we have some event to handle. */
        ret2 = pollfds[0].revents;
#if defined(ULIBSCTP_CONFIG_DEBUG)
        NSLog(@"pollfds[0].revents = %d",ret2);
#endif
        if(ret2 & POLLERR)
        {
            returnValue = [self getSocketError];
        }

        if(ret2 & POLLHUP)
        {
            if((returnValue==UMSocketError_no_data) || (returnValue==UMSocketError_no_error))
            {
                returnValue = UMSocketError_connection_reset;
            }
            *hasHup = 1;
        }
        if(ret2 & POLLNVAL)
        {
            returnValue = UMSocketError_file_descriptor_not_open;
        }
        /* There is data to read.*/
        if(ret2 & (POLLIN | POLLPRI))
        {
            *hasData = 1;
        }
        if(*hasData)
        {
            if(returnValue == UMSocketError_no_data)
            {
                returnValue = UMSocketError_has_data;
                if(*hasHup)
                {
                    returnValue = UMSocketError_has_data_and_hup;
                }
            }
        }
    }
    return returnValue;
}

- (UMSocketError) getSocketError
{
    int eno = 0;
    socklen_t len = sizeof(int);
    getsockopt(_sock, SOL_SOCKET, SO_ERROR, &eno, &len);
    return  [UMSocket umerrFromErrno:eno];
}


- (UMSocketError) setReusePort
{
#if defined(SCTP_REUSE_PORT)

    int flags = 1;
    int err = setsockopt(_sock, IPPROTO_SCTP, SCTP_REUSE_PORT, (char *)&flags, sizeof(flags));
    if(err !=0)
    {
        return [UMSocket umerrFromErrno:errno];
    }
    return    UMSocketError_no_error;
#else
    return UMSocketError_not_supported_operation;
#endif
}

- (UMSocketError) setNoDelay
{
#if defined(SCTP_NODELAY)
    int flags = 1;
    int err = setsockopt(_sock, IPPROTO_SCTP, SCTP_NODELAY, (char *)&flags, sizeof(flags));
    if(err !=0)
    {
        return [UMSocket umerrFromErrno:errno];
    }
    return    UMSocketError_no_error;
#else
    return UMSocketError_not_supported_operation;
#endif
}


- (UMSocketError) setInitParams
{
#if defined(SCTP_INITMSG)
    struct sctp_initmsg  params;
    memset((void *)&params,0x00, sizeof(struct sctp_initmsg));
    socklen_t len = sizeof(params);

    int err = getsockopt(_sock, IPPROTO_SCTP, SCTP_INITMSG, &params, &len);
    if(err==0)
    {
        if(_maxInStreams>0)
        {
            params.sinit_max_instreams = _maxInStreams;
        }
        if(_numOStreams>0)
        {
            params.sinit_num_ostreams = _numOStreams;
        }
        if(_maxInitAttempts>0)
        {
            params.sinit_max_attempts = _maxInitAttempts;
        }
        if(_initTimeout>0)
        {
            params.sinit_max_init_timeo = _initTimeout;
        }
        err = setsockopt(_sock, IPPROTO_SCTP, SCTP_INITMSG, &params, len);
    }
    if(err !=0)
    {
        return [UMSocket umerrFromErrno:errno];
    }
    return    UMSocketError_no_error;
#else
    return UMSocketError_not_supported_operation;
#endif
}


- (UMSocketError) listen: (int) backlog
{
    [self updateName];
    int err;
    self.status = UMSOCKET_STATUS_LISTENING;

    [self reportStatus:@"caling listen()"];
    if (self.isListening == 1)
    {
        [self reportStatus:@"- already listening"];
        return UMSocketError_already_listening;
    }
    self.isListening = 0;
    
    ummutex_lock(_controlLock);
    err = listen(_sock,backlog);
    ummutex_unlock(_controlLock);

    _direction = _direction | UMSOCKET_DIRECTION_INBOUND;
    if(err)
    {
        int eno = errno;
        return [UMSocket umerrFromErrno:eno];
    }
    self.isListening = 1;
#if defined(SCTP_LISTEN_FIX)
    int flag=1;
    ummutex_lock(_controlLock);
    setsockopt(_sock,IPPROTO_SCTP,SCTP_LISTEN_FIX,&flag,sizeof(flag));
    ummutex_unlock(_controlLock);
#endif
    [self reportStatus:@"isListening=1"];
    return UMSocketError_no_error;
}


- (NSArray *)getRemoteIpAddressesForAssoc:(uint32_t)assoc
{
#if !defined(HAS_SCTP)
    return NULL;
#else
    
    NSMutableArray *arr = [[NSMutableArray alloc]init];
    struct sockaddr *addrs=NULL;
    int e = sctp_getpaddrs(_sock, (sctp_assoc_t)assoc, &addrs);
    if(e<0)
    {
        if(addrs)
        {
            sctp_freepaddrs(addrs);
        }
        return NULL;
    }
    for(int i=0;i<e;i++)
    {
        NSString *a = [UMSocket addressOfSockAddr:&addrs[i]];
        if(a)
        {
            [arr addObject:a];
        }
    }
    return arr;
#endif
}

-(int)bindx:(struct sockaddr *)localAddress
{
#if !defined(HAS_SCTP)
    return -1;
#else

    int err = sctp_bindx(_sock, localAddress,1,SCTP_BINDX_ADD_ADDR);
    return err;
#endif
}

@end
