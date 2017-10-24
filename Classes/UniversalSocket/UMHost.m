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

#import "UMLock.h"

@implementation UMHost

@synthesize addresses;
@synthesize isLocalHost;
@synthesize isResolved;
@synthesize isResolving;
@synthesize name;

- (void) addAddress:(NSString *)a
{
	[addresses addObject:a];
}

- (UMHost *)  initWithLocalhost
{
    return [self initWithLocalhostAddresses:NULL];
}

- (UMHost *)  initWithLocalhostAddresses:(NSArray *)permittedAddresses
{
    self = [super init];
    if(self)
    {
        struct ifaddrs *ifadders = NULL;
        struct ifaddrs *ifptr = NULL;
        char	localHostName[256];
        char	ip[256];
        socklen_t sockLen;
        NSString	*n;
        
        addresses = [[NSMutableArray alloc] init];
        lock = [[NSLock alloc] init];
        
        isResolved = 0;
        
        if (getifaddrs (&ifptr) < 0)
        {
            int eno = errno;
            NSLog(@"UMhost: problem with getifaddrs. errno=%d",eno);
            return nil;
        }
        
        [self setIsLocalHost:1];
        [self setIsResolved:1];
        
        memset(localHostName,0,sizeof(localHostName));
        if(gethostname(localHostName, sizeof(localHostName)-1))
        {
            n = @"localhost";
        }
        else
        {
            n = [[NSString alloc] initWithUTF8String: localHostName];
        }
        self->name = n;
        
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
        addresses = [[NSMutableArray alloc] init];
        lock = [[NSLock alloc] init];
        isLocalHost = 0;
        isResolving = 0;
        isResolved = 0;
        self->name = n;
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
        lock = [[NSLock alloc] init];
        isLocalHost = 0;
        isResolving = 0;
        isResolved = 1;
        self.name = n;
    }
    return self;
}

- (NSString*) description
{
	NSString *s;
	s = [[NSString alloc] initWithFormat:@"UMHost: %@", self->name ? self->name : @"not set"];
	return s;
}

- (NSString *)address:(UMSocketType)type
{
    NSString *addr = nil;
    
	if([addresses count] > 0)
    {
        if (isLocalHost)
        {
            if (type == UMSOCKET_TYPE_TCP4ONLY || type == UMSOCKET_TYPE_UDP4ONLY ||
                    type == UMSOCKET_TYPE_SCTP4ONLY || type == UMSOCKET_TYPE_USCTP4ONLY)
            {
                addr = [addresses objectAtIndex:1];
            }
            else if (type == UMSOCKET_TYPE_TCP6ONLY || type == UMSOCKET_TYPE_UDP6ONLY ||
                    type == UMSOCKET_TYPE_SCTP6ONLY || type == UMSOCKET_TYPE_USCTP6ONLY)
            {
                addr = [addresses objectAtIndex:2];
            }
            else
            {
                addr = [addresses objectAtIndex:2];
            }
        }
        else
        {
            addr = [addresses objectAtIndex:0];
        }
        return addr;
    }
	return nil;
}

- (void)resolve
{
    ulib_set_thread_name([NSString stringWithFormat:@"UMHost: resolve(%@)",name]);

	char	namecstr[INET6_ADDRSTRLEN + 18];

    memset(namecstr,0x00,INET6_ADDRSTRLEN + 18);
    //memset(in_namecstr,0x00,256);
	if(isLocalHost == 1)
    {
		return;
    }
	if(isResolving)
	{
		while(isResolving == 1)
        {
			usleep(30000); /* wait 30ms */
        }
		return;
	}
	[lock lock];
	isResolving = 1;
	addresses = [[NSMutableArray alloc]init];	
    
    struct addrinfo *addrInfos = NULL;

    int res =getaddrinfo([name UTF8String] ,NULL, NULL, &addrInfos);
    if(res==0)
    {
        struct addrinfo *thisAddr = addrInfos;
        
        while(thisAddr)
        {            
            if((thisAddr->ai_family == AF_INET) || (thisAddr->ai_family == AF_INET6))
            {
                struct sockaddr_in *sa = (struct sockaddr_in *)thisAddr->ai_addr;
                inet_ntop(thisAddr->ai_family, &(sa->sin_addr), namecstr, sizeof(namecstr));
                [addresses addObject:@(namecstr)];
            }
            thisAddr = thisAddr->ai_next;
        }

        freeaddrinfo(addrInfos);
    }
    
	isResolving = 0;
	isResolved = 1;
	[lock unlock];
}

- (int) resolved
{
    int ret;
    
    [lock lock];
    ret = isResolved;
    [lock unlock];
    
    return ret;
}

- (int) resolving
{
    int ret;
    
    [lock lock];
    ret = isResolving;
    [lock unlock];
    
    return ret;
}

@end
