//
//  UMHost.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//



#include <sys/socket.h>
#include <netdb.h>

#import <ulib/UMHost.h>
#import <ulib/NSString+ulib.h>

#include <sys/types.h>
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <stdio.h>
#include <sys/uio.h>
#include <unistd.h>

#import <ulib/UMMutex.h>
#import <ulib/UMThreadHelpers.h>

#include <netinet/in.h>
#include <sys/socket.h>
#include <netdb.h>

@implementation UMHost

- (UMHost *)init
{
    self = [super init];
    if(self)
    {
        _addresses = [[NSMutableArray alloc]init];
        _hostLock = [[UMMutex alloc] initWithName:@"umhost"];
    }
    return self;
}

- (void) addAddress:(NSString *)a
{
    if(_hostLock == NULL)
    {
        _hostLock = [[UMMutex alloc] initWithName:@"umhost"];
    }
    ummutex_lock(_hostLock);
    if(_addresses == NULL)
    {
        _addresses = [[NSMutableArray alloc]init];
    }
	[_addresses addObject:a];
    ummutex_unlock(_hostLock);
}

- (UMHost *)  initWithLocalhost
{
    return [self initWithLocalhostAddresses:NULL];
}

+ (NSString *)localHostName
{
    char    localHostName[256];
    memset(localHostName,0,sizeof(localHostName));
    if(gethostname(localHostName, sizeof(localHostName)-1))
    {
        return @"localhost";
    }
    else
    {
        return @(localHostName);
    }
}

- (NSArray *)addresses
{
    NSArray *a;
    ummutex_lock(_hostLock);
    a = [_addresses copy];
    ummutex_unlock(_hostLock);
    return a;
}

- (void) setAddresses:(NSArray *)addresses
{
    ummutex_lock(_hostLock);
    _addresses = [addresses mutableCopy];
    ummutex_unlock(_hostLock);
}

- (UMHost *) initWithLocalhostAddresses:(NSArray *)permittedAddresses
{
    self = [super init];
    if(self)
    {
        struct ifaddrs *ifadders = NULL;
        struct ifaddrs *ifptr = NULL;
        char	ip[256];
        socklen_t sockLen;
        
        _addresses = [[NSMutableArray alloc] init];
        _hostLock = [[UMMutex alloc] initWithName:@"umhost"];

        self.isResolved = 0;
        if (getifaddrs (&ifptr) < 0)
        {
            int eno = errno;
            NSLog(@"UMhost: problem with getifaddrs. errno=%d",eno);
            return nil;
        }
        
        self.isLocalHost=YES;
        self.isResolved=YES;
        _name = [UMHost localHostName];
        
        for (ifadders = ifptr; ifadders; ifadders = ifadders->ifa_next)
        {
            if(! ifadders->ifa_addr)
            {
                continue;
            }
            if (ifadders->ifa_addr->sa_family == AF_INET)
            {
                sockLen = sizeof (struct sockaddr_in);
            }
            else if (ifadders->ifa_addr->sa_family == AF_INET6)
            {
                sockLen = sizeof (struct sockaddr_in6);
            }
            else
            {
                continue;
            }
            memset(ip,0,sizeof(ip));
            if (getnameinfo (ifadders->ifa_addr,sockLen, ip, sizeof (ip)-1,NULL,0,NI_NUMERICHOST) <  0)
            {
                NSLog(@"UMhost: problem with getnameinfo");
                continue;
            }
            NSString *unifiedIp =  [UMSocket unifyIP:@(ip)];

            if(permittedAddresses)
            {
                for(NSString *permittedIp in permittedAddresses)
                {

                    /* UNIFY /DEUNIFY */
                    if([unifiedIp isEqualToString:permittedIp])
                    {
                        [self addAddress:unifiedIp];
                    }
                }
            }
            else
            {
                [self addAddress:unifiedIp];
            }
        }
        freeifaddrs (ifptr);
        ifptr = NULL;
    }
    return self;
}

- (UMHost *)  initWithName:(NSString *)n
{
    if(n==NULL)
    {
        return NULL;
    }
    self = [super init];
    if (self)
    {
        _hostLock = [[UMMutex alloc] initWithName:@"umhost"];
        _addresses = [[NSMutableArray alloc] init];
        self.isLocalHost = 0;
        self.isResolving = 0;
        self.isResolved = 0;
        _name = n;
        [self runSelectorInBackground:@selector(resolve)
                           withObject:nil
                                 file:__FILE__
                                 line:__LINE__
                             function:__func__];
//        [NSThread detachNewThreadSelector:@selector(resolve) toTarget:self withObject:nil];
    }
	return self;
}

- (UMHost *)  initWithAddress:(NSString *)n
{
    if(n==NULL)
    {
        return NULL;
    }
    self = [super init];
    if (self)
    {
        _hostLock = [[UMMutex alloc] initWithName:@"umhost"];
        self.isLocalHost = 0;
        self.isResolving = 0;
        self.isResolved = 1;
        n = [UMSocket unifyIP:n];
        self.addresses = [NSMutableArray arrayWithObjects:n,nil];
        _name = n;
    }
    return self;
}

- (NSString*) description
{
	NSString *s;
	s = [[NSString alloc] initWithFormat:@"UMHost: %@", _name ? _name : @"not set"];
	return s;
}

- (NSString *)address:(UMSocketType)type
{
    while(self.isResolving)
    {
        usleep(30000); /* wait 30ms */
    }
    NSString *addr = nil;
    ummutex_lock(_hostLock);
	if([_addresses count] > 0)
    {
        if (self.isLocalHost)
        {
            if (UMSOCKET_IS_IPV4_ONLY_TYPE(type))
            {
                return @"127.0.0.1";
            }
            else if (UMSOCKET_IS_IPV6_ONLY_TYPE(type))
            {
                return @"::1";
            }
            else
            {
                return @"::1";
            }
        }
        else
        {
            if (UMSOCKET_IS_IPV4_ONLY_TYPE(type))
            {
                /* returning the first IPv4 address */
                for(NSString *s in _addresses)
                {
                    if([s hasPrefix:@"ipv4:"])
                    {
                        addr = s;
                        break;
                    }
                }
                return NULL;
            }
            else if (UMSOCKET_IS_IPV6_ONLY_TYPE(type))
            {
                /* returning the first IPv6 address */
                for(NSString *s in _addresses)
                {
                    if([s hasPrefix:@"ipv6:"])
                    {
                        addr = s;
                        break;
                    }
                }
            }
            else
            {
                /* returning the last IPv6 address if found. otherwise the last IPv4 */
                NSString *ipv4 = NULL;
                NSString *ipv6 = NULL;
                    /* returning the first IPv4 address */
                for(NSString *s in _addresses)
                {
                    if([s hasPrefix:@"ipv4:"])
                    {
                        ipv4 = s;
                    }
                    if([s hasPrefix:@"ipv6:"])
                    {
                        ipv6 = s;
                    }
                    if(ipv6)
                    {
                        break;
                    }
                }
                if(ipv6)
                {
                    addr = ipv6;
                }
                else
                {
                    addr = ipv4;
                }
            }
        }
    }
    ummutex_unlock(_hostLock);
    addr = [UMSocket deunifyIp:addr];
    return addr;
}

- (void)resolve
{
    ulib_set_thread_name([NSString stringWithFormat:@"UMHost: resolve(%@)",_name]);
    char	namecstr[INET6_ADDRSTRLEN + 18];
    memset(namecstr,0x00,INET6_ADDRSTRLEN + 18);
	if(self.isLocalHost)
    {
		return;
    }
	if(self.isResolving)
	{
		while(self.isResolving)
        {
			usleep(30000); /* wait 30ms */
        }
		return;
	}
    ummutex_lock(_hostLock);
	self.isResolving = YES;
	_addresses = [[NSMutableArray alloc]init];
    
    struct addrinfo *addrInfos = NULL;
    int res =getaddrinfo([_name UTF8String] ,NULL, NULL, &addrInfos);
    if(res==0)
    {
        struct addrinfo *thisAddr = addrInfos;
        while(thisAddr)
        {
            if(thisAddr->ai_family == AF_INET)
            {
                struct sockaddr_in *sa4 = (struct sockaddr_in *)thisAddr->ai_addr;
                inet_ntop(thisAddr->ai_family, &(sa4->sin_addr), namecstr, sizeof(namecstr));
            }
            else if (thisAddr->ai_family == AF_INET6)
            {
                struct sockaddr_in6 *sa6 = (struct sockaddr_in6 *)thisAddr->ai_addr;
                inet_ntop(thisAddr->ai_family, &(sa6->sin6_addr), namecstr, sizeof(namecstr));
            }
            else
            {
                continue;
            }
            BOOL dup=NO;
            for(NSString *s in _addresses)
            {
                if([s isEqualToString:@(namecstr)])
                {
                    dup=YES;
                }
            }
            if(dup==NO)
            {
                [_addresses addObject:@(namecstr)];
            }
            thisAddr = thisAddr->ai_next;
        }
        freeaddrinfo(addrInfos);
    }
    self.isResolving = 0;
	self.isResolved = 1;
    ummutex_unlock(_hostLock);
}

- (int) resolved
{
    ummutex_lock(_hostLock);
    BOOL r = self.isResolved;
    ummutex_unlock(_hostLock);
    return r;
}

- (int) resolving
{
    ummutex_lock(_hostLock);
    BOOL r = self.isResolving;
    ummutex_unlock(_hostLock);
    return r;
}

- (NSString *)address
{
    if(_addresses.count>0)
    {
        return _addresses[0];
    }
    return @"";
}

+ (NSString *)reveseDnsName:(NSString *)addr
{
    struct sockaddr_in  sa_in4;
    struct sockaddr_in6 sa_in6;
    struct sockaddr     *sa;
    memset(&sa_in4,0,sizeof(sa_in4));
    memset(&sa_in6,0,sizeof(sa_in6));
    int result = 0;
    socklen_t salen;
    if([addr isIPv4])
    {
        addr = [UMSocket deunifyIp:addr];
        
        sa_in4.sin_len = sizeof(struct sockaddr_in);
        sa_in4.sin_family = AF_INET;
        result = inet_pton(AF_INET,addr.UTF8String,&sa_in4.sin_addr);
        sa = (struct sockaddr *)&sa_in4;
        salen = sizeof(struct sockaddr_in);
    }
    else if([addr isIPv6])
    {
        sa_in6.sin6_len = sizeof(struct sockaddr_in6);
        sa_in6.sin6_family = AF_INET6;
        addr = [UMSocket deunifyIp:addr];
        result = inet_pton(AF_INET6,addr.UTF8String,  &sa_in6.sin6_addr);
        sa = (struct sockaddr *)&sa_in6;
        salen = sizeof(sa_in6);
    }
    else
    {
        return NULL;
    }
    char hostBuffer[NI_MAXHOST];
    memset(hostBuffer,0,sizeof(hostBuffer));
    int err = getnameinfo(sa,salen,&hostBuffer[0],sizeof(hostBuffer),NULL,0,NI_NAMEREQD);
    if(err == 0)
    {
        return @(hostBuffer);
    }
    return NULL;
}

@end
