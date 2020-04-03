//
//  UMHost.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//



#include <sys/socket.h>
#include <netdb.h>

#import "UMHost.h"

#include <sys/types.h>
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <stdio.h>
#include <sys/uio.h>
#include <unistd.h>

#import "UMMutex.h"
#import "UMThreadHelpers.h"

#include <netinet/in.h>

@implementation UMHost

- (void) addAddress:(NSString *)a
{
    [_lock lock];
	[_addresses addObject:a];
    [_lock unlock];
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
    [_lock lock];
    a = [_addresses copy];
    [_lock unlock];
    return a;
}

- (void) setAddresses:(NSArray *)addresses
{
    [_lock lock];
    _addresses = [addresses mutableCopy];
    [_lock unlock];

}

- (UMHost *)  initWithLocalhostAddresses:(NSArray *)permittedAddresses
{
    self = [super init];
    if(self)
    {
        struct ifaddrs *ifadders = NULL;
        struct ifaddrs *ifptr = NULL;
        char	ip[256];
        socklen_t sockLen;
        
        _addresses = [[NSMutableArray alloc] init];
        _lock = [[UMMutex alloc] initWithName:@"umhost"];

        _isResolved = 0;
        
        if (getifaddrs (&ifptr) < 0)
        {
            int eno = errno;
            NSLog(@"UMhost: problem with getifaddrs. errno=%d",eno);
            return nil;
        }
        
        _isLocalHost=1;
        _isResolved=1;
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
        _addresses = [[NSMutableArray alloc] init];
        _lock = [[UMMutex alloc] initWithName:@"umhost"];
        _isLocalHost = 0;
        _isResolving = 0;
        _isResolved = 0;
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
        self.addresses = [NSMutableArray arrayWithObjects:n,nil];
        _lock = [[UMMutex alloc] initWithName:@"umhost"];
        _isLocalHost = 0;
        _isResolving = 0;
        _isResolved = 1;
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
    NSString *addr = nil;
    [_lock lock];
	if([_addresses count] > 0)
    {
        if (_isLocalHost)
        {
            if (UMSOCKET_IS_IPV4_ONLY_TYPE(type))
            {
                addr = [_addresses objectAtIndex:1];
            }
            else if (UMSOCKET_IS_IPV6_ONLY_TYPE(type))
            {
                addr = [_addresses objectAtIndex:2];
            }
            else
            {
                addr = [_addresses objectAtIndex:2];
            }
        }
        else
        {
            addr = [_addresses objectAtIndex:0];
        }
    }
    [_lock unlock];
    return addr;
}

- (void)resolve
{
    ulib_set_thread_name([NSString stringWithFormat:@"UMHost: resolve(%@)",_name]);

    char	namecstr[INET6_ADDRSTRLEN + 18];
    memset(namecstr,0x00,INET6_ADDRSTRLEN + 18);
    //memset(in_namecstr,0x00,256);
	if(self.isLocalHost == 1)
    {
		return;
    }
	if(self.isResolving)
	{
		while(self.isResolving == 1)
        {
			usleep(30000); /* wait 30ms */
        }
		return;
	}
    [_lock lock];
	_isResolving = 1;
	_addresses = [[NSMutableArray alloc]init];
    
    struct addrinfo *addrInfos = NULL;

    int res =getaddrinfo([_name UTF8String] ,NULL, NULL, &addrInfos);
    if(res==0)
    {
        struct addrinfo *thisAddr = addrInfos;
        
        while(thisAddr)
        {            
            if((thisAddr->ai_family == AF_INET) || (thisAddr->ai_family == AF_INET6))
            {
                struct sockaddr_in *sa = (struct sockaddr_in *)thisAddr->ai_addr;
                inet_ntop(thisAddr->ai_family, &(sa->sin_addr), namecstr, sizeof(namecstr));
                [_addresses addObject:@(namecstr)];
            }
            thisAddr = thisAddr->ai_next;
        }

        freeaddrinfo(addrInfos);
    }
    
	_isResolving = 0;
	_isResolved = 1;
	[_lock unlock];
}

- (int) resolved
{
    int ret;
    
    [_lock lock];
    ret = _isResolved;
    [_lock unlock];
    
    return ret;
}

- (int) resolving
{
    int ret;
    
    [_lock lock];
    ret = _isResolving;
    [_lock unlock];
    return ret;
}

@end
