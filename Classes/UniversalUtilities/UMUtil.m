//
//  UMUtil.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMUtil.h"
#import <pthread.h>
#include "ulib_config.h"

/* byte order stuff: we use macros under MacOS X */
#if defined __APPLE__

#include <TargetConditionals.h>
#include <libkern/OSByteOrder.h>
#include <IOKit/IOTypes.h>

#else  /* ! _APPLE__ */
#include <bsd/stdlib.h>
#endif


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/time.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/utsname.h>
#include <netinet/in.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <time.h>
#include <pthread.h>
#include <execinfo.h>
#include <ifaddrs.h>
#include <sys/wait.h>

#if defined(HAVE_SYS_SOCKIO_H)
#include <sys/sockio.h>
#endif
#include <net/if.h>
#include <errno.h>

#if defined(HAVE_NET_IF_DL_H)
#include <net/if_dl.h>
#endif

#ifdef __APPLE__
#define AF_MACADDR AF_LINK
#else
#define AF_MACADDR AF_NETLINK
#endif

#import "UMSocket.h"

static const unsigned char base32char[32] =
{
	'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h',
	'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p',
	'q', 'r', 's', 't', 'u', 'v', 'w', 'x',
	'y', 'z', '2', '3', '4', '5', '6', '7'
};

static const unsigned char base32map[256] =
{
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0,  26,  27,  28,  29,  30,  31, 0, 0, 0, 0, 0, 0, 0, 0,
	0,   0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13,  14,
	 15,  16,  17,  18,  19,  20,  21,  22,  23,  24,  25, 0, 0, 0, 0, 0,
	0,   0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13,  14,
	 15,  16,  17,  18,  19,  20,  21,  22,  23,  24,  25, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
};

static NSDictionary *   _localMacAddrs = NULL;
static BOOL             _localMacAddrsLoaded = NO;
static NSDictionary *   _localIpAddrs = NULL;
static BOOL             _localIpAddrsLoaded = NO;
static NSString *       _machineSerialNumber = NULL;
static BOOL             _machineSerialNumberLoaded = NO;
static NSString *       _machineUUID = NULL;
static BOOL             _machineUUIDLoaded = NO;
static NSArray *        _machineCPUIDs = NULL;
static BOOL             _machineCPUIDsLoaded = NO;

@implementation UMUtil

+ (NSMutableData *)base32:(NSMutableData *)input
{
	NSMutableData *out;
	size_t i;
	size_t j;
	size_t k;
	unsigned char s[8];
	unsigned char x[8];
    unsigned char *in;
	long len;
	

	out = [[NSMutableData alloc] init];
	in	= (unsigned char *)[input bytes];
	len = [input length];

	i = 0;
	while(i < len)
	{
		/* k is the number of input bytes to process in this run*/
		k = len - i;
		if (k > 5)
			k=5;

		memset(&x[0],0,5);
		for(j=0;j<k;j++)
			x[j] = in[i+j];
		s[0] = base32char [(x[0] >> 3)];
		s[1] = base32char [((x[0] & 0x07) << 2) | ((x[1] >> 6) & 0x03)];
		s[2] = base32char [(x[1] >> 1) & 0x1F];
		s[3] = base32char [((x[1] & 0x01) << 4) |  (x[2] >> 4)];
		s[4] = base32char [((x[2] & 0x0F) << 1) | ((x[3] >> 7) & 0x01)];
		s[5] = base32char [(x[3] >> 2) & 0x1f];
		s[6] = base32char [((x[3] & 0x03) << 3) | ((x[4] >> 5) & 0x7)];
		s[7] = base32char [(x[4] & 0x1F)];
		switch (k)
		{
			case 1:
				[out appendBytes: &s[0] length:2];
				break;
			case 2:
				[out appendBytes: &s[0] length:4];
				break;
			case 3:
				[out appendBytes: &s[0] length:5];
				break;
			case 4:
				[out appendBytes: &s[0] length:7];
				break;
			default:
				[out appendBytes: &s[0] length:8];
				break;
		}
		i += 5;
	}
	s[0] = 0;
	[out appendBytes: &s[0] length:1];
	return out;
}

+(NSMutableData *)unbase32:(NSMutableData *)input
{
	NSMutableData *out;
	unsigned char  s[8];
	unsigned char  b[5];
	size_t i;
	size_t j;
	size_t k;
	
	unsigned char	*in;
	size_t			len;

	in			= (unsigned char	*)[input bytes];
	len	= [input length];
	
	out = [[NSMutableData alloc] init];

	if (in[len-1] =='\0')
		len--;
	i = 0;
	while(i < len)
	{
		/* k is the number of input bytes to process in this run*/
		k = len - i;
		if (k > 8)
			k=8;
		memset(&s[0],0,8);
		for(j=0;j<k;j++)
			s[j] =base32map[in[i+j]];

		b[0] =  ((s[0]<< 3) & 0xF8)  | ((s[1] >> 2) & 0x07);
		b[1] =	((s[1] & 0x03) << 6) | ((s[2] & 0x1f) << 1) | ((s[3] >> 4) & 1);
		b[2] =	((s[3] & 0x0f) << 4) | ((s[4] >> 1) & 0x0f);
		b[3] =	((s[4] & 1) << 7)    | ((s[5] & 0x1f) << 2) | ((s[6] >> 3) & 0x03);
		b[4] =	((s[6] & 0x07) << 5) |  (s[7] & 0x1f);

		switch (k)
		{
			case 1:
				/* not enough ata */
				break;
			case 2:
			case 3:
				[out appendBytes: &b[0] length:1];
				break;
			case 4:
				[out appendBytes: &b[0] length:2];
				break;
			case 5:
			case 6:
				[out appendBytes: &b[0] length:3];
				break;
			case 7:
				[out appendBytes: &b[0] length:4];
				break;
			default:
				[out appendBytes: &b[0] length:5];
				break;
		}
		i+=8;
	}
	return out;
}

+ (NSString *) sysName
{
	struct utsname u;
	uname(&u);
	return @(&u.sysname[0]);
}

+ (NSString *) nodeName
{
	struct utsname u;
	uname(&u);
	return @(&u.nodename[0]);
}

+ (NSString *) osRelease
{
	struct utsname u;
	uname(&u);
	return @(&u.release[0]);
}


+ (NSString *) version
{
	struct utsname u;
	uname(&u);
	return @(&u.version[0]);
}

+ (NSString *) machine
{
	struct utsname u;
	uname(&u);
	return @(&u.machine[0]);
}

+ (NSString *) version1
{
	char *p;
	struct utsname u;
	uname(&u);
	p = strstr(&u.version[0],":");
	if(p)
    {
		*p = '\0';
    }
	return @(&u.version[0]);
}

+ (NSString *) version2
{
	char *p;
	char *p2;
	struct utsname u;
	uname(&u);
	p = strstr(&u.version[0],":");
	if(p)
    {
		*p = '\0';
    }
	p++;
	p2 = strstr(p,";");
	if(p2)
    {
		*p2 = '\0';
	}
	return @(p);
}

+ (NSString *) version3
{
	char *p;
	char *p2;
	struct utsname u;
	uname(&u);
	p = strstr(&u.version[0],";");
	if(p)
    {
		*p = '\0';
    }
	p++;
	p2 = strstr(p,"/");
	if(p2)
    {
		*p2 = '\0';
    }
	return @(p);
}

+ (NSString *) version4
{
	char *p;
	struct utsname u;
	uname(&u);
	p = strstr(&u.version[0],"/");
	if(p)
    {
		p++;
    }
	else
    {
		p = &u.version[0];
    }
	return @(p);
}


+ (NSString *)getMacAddrForInterface: (NSString *)ifname
{
    NSDictionary *addrs = [self getMacAddrs];
    return addrs[ifname];
}


+ (NSArray *)getArrayOfMacAddresses
{
    NSMutableArray *a =[[NSMutableArray alloc]init];
    
    NSDictionary *macs = [UMUtil getMacAddrsWithCaching:YES];
    NSArray *interfaceNames = [macs allKeys];
    for(NSString *interfaceName in interfaceNames)
    {
        NSString *mac = macs[interfaceName];
        if(![mac isEqualToString:@"000000000000"])
        {
            [a addObject:macs[interfaceName]];
        }
    }
    return a;
}

+ (NSDictionary<NSString *,NSString *>*)getMacAddrs
{
    return [UMUtil getMacAddrsWithCaching:YES];
}


+ (NSDictionary<NSString *,NSString *>*)getMacAddrsWithCaching:(BOOL)useCache
{
    if((_localMacAddrsLoaded) && (useCache == YES))
    {
        return _localMacAddrs;
    }

    struct ifaddrs   *ifaphead;
    unsigned char *   if_mac;
    int               found = 0;
    struct ifaddrs   *ifap = NULL;
#ifdef __APPLE__
    struct sockaddr_dl *sdl = NULL;
#endif
    NSMutableDictionary	*dict =  [[NSMutableDictionary alloc] init];
    if (getifaddrs(&ifaphead) != 0)
    {
        perror("get_if_name: getifaddrs() failed");
        _localMacAddrs = dict;
    }
	else
    {
        for (ifap = ifaphead; ifap && !found; ifap = ifap->ifa_next)
        {
#if defined(__APPLE__)
            if (ifap->ifa_addr->sa_family == AF_MACADDR)
            {
                sdl = (struct sockaddr_dl *)ifap->ifa_addr;
                if (sdl)
                {
                    /* I was returning this from a function before converting
                     * this snippet, which is why I make a copy here on the heap */
                //	if_mac = malloc(sdl->sdl_alen);
                    if_mac = (unsigned char *)LLADDR(sdl);
                }
                NSString *ifname = @(ifap->ifa_name);
                NSString *macaddr= [NSString stringWithFormat: @"%02X%02X%02X%02X%02X%02X",
                                    if_mac[0],if_mac[1], if_mac[2],if_mac[3],if_mac[4],if_mac[5]];
                dict[ifname] = macaddr;
            }
#else
            struct ifreq buffer;
            int s = socket(PF_INET, SOCK_DGRAM, 0);
            memset(&buffer, 0x00, sizeof(buffer));
            strcpy(buffer.ifr_name, ifap->ifa_name);
            ioctl(s, SIOCGIFHWADDR, &buffer);
            close(s);
            if_mac = (unsigned char *)&buffer.ifr_hwaddr.sa_data[0];
            NSString *ifname = @(ifap->ifa_name);
            NSString *macaddr= [NSString stringWithFormat: @"%02X%02X%02X%02X%02X%02X",
                       if_mac[0],if_mac[1], if_mac[2],if_mac[3],if_mac[4],if_mac[5]];
            dict[ifname] = macaddr;
#endif
        }
        _localMacAddrs = dict;
        freeifaddrs(ifaphead);
        ifaphead = NULL;
    }
    _localMacAddrsLoaded = YES;
    return _localMacAddrs;
}


+(NSArray *)getNonLocalIPs
{
    NSArray *localPrefixes = @[
                               @"0.",
                               @"10.",
                               @"169.254.",
                               @"192.168.",
                               @"172.16.",
                               @"172.17.",
                               @"172.18.",
                               @"172.19.",
                               @"172.20.",
                               @"172.21.",
                               @"172.22.",
                               @"172.23.",
                               @"172.24.",
                               @"172.25.",
                               @"172.26.",
                               @"172.27.",
                               @"172.28.",
                               @"172.29.",
                               @"172.30.",
                               @"172.31.",
                               @"fe80:",
                               @"::",
                               ];
    NSMutableArray *results = [[NSMutableArray alloc]init];
    
    NSDictionary<NSString *,NSArray<NSDictionary<NSString *,NSString *> *> *> *interface_ips;
    interface_ips = [UMUtil getIpAddrs];
    NSArray *interface_names = [interface_ips allKeys];
    for(NSString *interface_name in interface_names)
    {
        NSArray<NSDictionary<NSString *,NSString *> *> *ips_per_if = interface_ips[interface_name];
        for(NSDictionary<NSString *,NSString *> *entry in ips_per_if)
        {
            NSString *ip = entry[@"address"];
            //NSString *netmask = entry[@"netmask"];
            for(NSString *localPrefix in localPrefixes)
            {
                if([ip hasPrefix:localPrefix])
                {
                    continue;
                }
            }
            [results addObject:ip];
        }
    }
    return results;
}

+ (NSDictionary<NSString *,NSArray<NSDictionary<NSString *,NSString *> *> *>*)getIpAddrs;
{
    return [UMUtil getIpAddrsWithCaching:YES];
}

+ (NSDictionary<NSString *,NSArray<NSDictionary<NSString *,NSString *> *> *>*)getIpAddrsWithCaching:(BOOL)useCache
{
    if((_localIpAddrsLoaded) && (useCache == YES))
    {
        return _localIpAddrs;
    }

    struct ifaddrs   *ifaphead;
    int               found = 0;
    struct ifaddrs   *ifap = NULL;
    NSMutableDictionary    *dict =  [[NSMutableDictionary alloc] init];
    if (getifaddrs(&ifaphead) != 0)
    {
        perror("get_if_name: getifaddrs() failed");
        _localMacAddrs = dict;
    }
    else
    {
        NSMutableArray *a;
        for (ifap = ifaphead; ifap && !found; ifap = ifap->ifa_next)
        {
            NSString *ifname = @(ifap->ifa_name);
            if ((ifap->ifa_addr->sa_family == AF_INET) || (ifap->ifa_addr->sa_family == AF_INET6))
            {
                struct sockaddr *sa = (struct sockaddr *)ifap->ifa_addr;
                struct sockaddr *mask = (struct sockaddr *)ifap->ifa_netmask;
                NSString *addr = [UMSocket addressOfSockAddr:sa];
                NSString *netmask = [UMSocket addressOfSockAddr:mask];
                if(netmask.length==0)
                {
                    if(ifap->ifa_addr->sa_family == AF_INET)
                    {
                        netmask = @"255.255.255.255";
                    }
                    else
                    {
                        netmask = @"ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff";
                    }
                }
                NSDictionary *dict2 = @{ @"address" : addr, @"netmask" : netmask};

                a = dict[ifname];
                if(a==0)
                {
                    a = [[NSMutableArray alloc]init];
                }
                [a addObject:dict2];
                dict[ifname] = a;

            }
        }
        freeifaddrs(ifaphead);
        ifaphead = NULL;
        _localIpAddrs = dict;
        _localIpAddrsLoaded = YES;
    }
    return _localIpAddrs;
}

+ (long long) milisecondClock;
{
	struct	timeval  tp;
	struct	timezone tzp;
	
    gettimeofday(&tp, &tzp);
    
	return (unsigned long long)tp.tv_sec * 1000ULL + ((unsigned long long)tp.tv_usec/1000ULL);
    
}

+ (uint32_t)  random:(uint32_t)upperBound
{
    return arc4random_uniform(upperBound);
}

+ (uint32_t)  randomFrom:(uint32_t)lowerBound to:(uint32_t)upperBound
{
    return arc4random_uniform(upperBound-lowerBound) + lowerBound;
}

+ (uint32_t)  random
{
    return arc4random_uniform(UINT_MAX);
}


+ (NSString *)getMachineSerialNumber
{
    if(_machineSerialNumberLoaded)
    {
        return _machineSerialNumber;
    }
    BOOL found = NO;

#if defined(__APPLE__)
    NSString *serialNumber = NULL;
#if defined(TARGETOSIPHONE)
    serialNumber = [[UIDevice currentDevice] uniqueIdentifier];
#else
    CFStringRef cfSerialNumber = NULL;
    io_service_t platformExpert = IOServiceGetMatchingService(   kIOMasterPortDefault,
                                                              IOServiceMatching("IOPlatformExpertDevice")
                                                              );

    if (platformExpert)
    {
        CFTypeRef serialNumberAsCFString = IORegistryEntryCreateCFProperty(
                                                                           platformExpert,
                                                                           CFSTR(kIOPlatformSerialNumberKey),
                                                                           kCFAllocatorDefault,
                                                                           0
                                                                           );
        cfSerialNumber = (CFStringRef)serialNumberAsCFString;
        IOObjectRelease(platformExpert);
    }
    if (cfSerialNumber)
    {
        serialNumber = @ ([(NSString *)CFBridgingRelease(cfSerialNumber) UTF8String]);
        found = YES;
    }
    else
    {
        serialNumber = @"unknown";
    }
#endif
#else /* ! __APPLE___ */


#define MAXLINE 256
    NSMutableString *serialNumber = NULL;
    NSArray *cmd = [NSArray arrayWithObjects:@"/usr/sbin/dmidecode",@"-t",@"system",NULL];
    NSArray *lines = [UMUtil readChildProcess:cmd];
    for (NSString *line in lines)
    {
        const char *s = strstr([line UTF8String],"Serial Number: ");
        if(s)
        {
            s += strlen("Serial Number: ");
            size_t len = strlen(s);
            int i;
            serialNumber = [[NSMutableString alloc] init];
            for(i=0;i<len;i++)
            {
                switch(s[i])
                {
                    case '\0':
                    case '\n':
                    case '\r':
                    case '\t':
                    case ' ':
                        break;
                    default:
                        [serialNumber appendFormat:@"%c",s[i]];
                        break;
                }
            }
            found=YES;
        }
    }
#endif
    if(found)
    {
        _machineSerialNumber = serialNumber;
        _machineSerialNumberLoaded = YES;
        return _machineSerialNumber;
    }
    return @"unknown";
}


+ (NSString *)getMachineUUID
{
    if(_machineUUIDLoaded)
    {
        return _machineUUID;
    }

#if defined(__APPLE__)
    _machineUUID = [UMUtil getMachineSerialNumber];;
    _machineUUIDLoaded = _machineSerialNumberLoaded;
    return _machineUUID;

#else // !__APPLE
    NSString *uuidNumber = NULL;
    BOOL found = NO;

    NSArray *cmd = [NSArray arrayWithObjects:@"/usr/sbin/dmidecode",@"-t",@"system",NULL];
    NSArray *lines = [UMUtil readChildProcess:cmd];
    for (NSString *line in lines)
    {
        const char *s = strstr([line UTF8String],"UUID: ");
        if(s)
        {
            s += strlen("UUID: ");
            uuidNumber = [[ NSString stringWithUTF8String: s]
                          stringByTrimmingCharactersInSet:[UMObject whitespaceAndNewlineCharacterSet]];
            found=YES;
        }
    }

    if(found)
    {
        _machineUUID = uuidNumber;
        _machineUUIDLoaded = YES;
        return _machineUUID;
    }
    return @"unknown";
#endif
}

#define RXPIPE    0
#define TXPIPE    1


+(NSArray *)readChildProcess:(NSArray *)args
{
    int pipefds[2];
    pid_t pid;
    NSMutableArray *result = NULL;
    if(pipe(pipefds)< 0)
    {
        return NULL;
    }
    pid = fork();
    if(pid==-1)
    {
        return NULL;
    }
    if(pid==0)
    {
        /* child process */
        dup2(pipefds[TXPIPE], STDOUT_FILENO);
        close(pipefds[RXPIPE]);
        
        char  **cmd=NULL;
        int n = (int)[args count];
        int i;
        cmd = calloc(sizeof (char *),n+1);
        for(i=0;i<n;i++)
        {
            cmd[i]=(char *)[args[i] UTF8String];
        }
        if (execvp(cmd[0], cmd) == -1)
        {
            if(cmd)
            {
                free(cmd);
                cmd=NULL;
            }
            exit(-1);
        }
        exit(0);
    }
    else
    {
        int returnStatus=0;
        waitpid(pid, &returnStatus, 0);
        close(pipefds[TXPIPE]);
        
        FILE *fromChild = fdopen(pipefds[RXPIPE], "r");
        
        result = [[NSMutableArray alloc]init];
        
        char line[257];
        size_t linecap=255;
        
        /*
         char *line=NULL;
         size_t linecap=255;
         ssize_t linelen;
         while ((linelen = getline(&line, &linecap, fromChild)) > 0)
         */
        while(fgets(line, (int)linecap, fromChild))
        {
            [result addObject:@(line)];
            if(feof(fromChild))
            {
                break;
            }
        }
        //       if(line)
        //       {
        //           free(line);
        //           line = NULL;
        //       }
    }
    return result;
}

+ (NSArray *)getCPUSerialNumbers
{
    if(_machineCPUIDsLoaded)
    {
        return _machineCPUIDs;
    }
    
    
    NSArray *cmd = [NSArray arrayWithObjects:@"/usr/sbin/dmidecode",@"-t",@"processor",NULL];
    NSArray *lines = [UMUtil readChildProcess:cmd];
    NSMutableArray  *serialNumbers = [[NSMutableArray alloc]init];
    int found = 0;
    
    for(NSString *line in lines)
    {
        const char *s = strstr([line UTF8String],"ID: ");
        if(s)
        {
            s += strlen("ID: ");
            size_t len = strlen(s);
            int i;
            NSMutableString *serialNumber = [[NSMutableString alloc] init];
            for(i=0;i<len;i++)
            {
                switch(s[i])
                {
                    case '\0':
                    case '\n':
                    case '\r':
                    case '\t':
                    case ' ':
                        break;
                    default:
                        [serialNumber appendFormat:@"%c",s[i]];
                        break;
                }
            }
            if([serialNumbers indexOfObjectIdenticalTo:serialNumber]==NSNotFound)
            {
                [serialNumbers addObject:serialNumber];
            }
            serialNumber = NULL;
            found++;
        }
    }
    if(found==0)
    {
        serialNumbers=NULL;
        return NULL;
    }
    _machineCPUIDsLoaded = YES;
    _machineCPUIDs = serialNumbers;
    return serialNumbers;
}
@end


NSString *UMBacktrace(void **stack_frames, size_t size)
{
    void *frames[50];
    size_t i;
    char **strings;
    
    NSString *threadName = ulib_get_thread_name(pthread_self());

	NSMutableString *s = [[NSMutableString alloc]init];
    [s appendFormat:@"\n CurrentThread: %@\r\n",threadName];

    if (stack_frames == NULL)
    {
        stack_frames = frames;
        size = backtrace(stack_frames, sizeof(frames) / sizeof(void*));
    }
    
    strings = backtrace_symbols(stack_frames,(int)size);
    
    if (strings)
    {
        for (i = 0; i < size; i++)
        {
            [s appendFormat:@" %s\r\n", strings[i]];
        }
    }
    else
    {
        for (i = 0; i < size; i++)
        {
            [s appendFormat:@" %p\r\n", stack_frames[i]];
        }
    }
    free(strings);
    return s;
}

#if defined(LINUX)

#include <sys/types.h>
#include "unistd.h"
#include <sys/syscall.h>
#include <sys/prctl.h>
extern int pthread_setname_np (pthread_t __target_thread, __const char *__name);

uint64_t ulib_get_thread_id(void)
{
    uint64_t tid = (uint64_t)syscall (SYS_gettid);
    return tid;
}

#elif defined(__APPLE__)

uint64_t ulib_get_thread_id(void)
{
    uint64_t tid = 0;
    pthread_t me = pthread_self();
    pthread_threadid_np(me,&tid);
    return tid;
}
#else

#error  We need gettid()

#endif


#if defined(LINUX) || defined(__APPLE__)
extern int pthread_getname_np (pthread_t thread, char *buf,size_t len);
NSString *ulib_get_thread_name(pthread_t thread)
{
    char name[256];
    memset(name,0x00,256);
    pthread_getname_np (thread, &name[0],255);
    return [NSString stringWithUTF8String:name];
}
#else
#error We need something like pthread_getname_np defined
#endif
