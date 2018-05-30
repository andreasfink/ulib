//
//  UMUtil.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMUtil.h"

#ifndef	LINUX
#include <libkern/OSByteOrder.h>
#else
#include <bsd/stdlib.h>
#endif
#include <arpa/inet.h>

#include <sys/utsname.h>
#include <time.h>
#include <sys/time.h>
#include <pthread.h>
#include <execinfo.h>

#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#ifdef __APPLE__
#include <net/if_dl.h>
#endif
#include <ifaddrs.h>


/* TODO: find correct endianness for Linux. Currently we assume i386 arch only */
#ifdef	LINUX

#ifndef	ntohll
#define ntohll(x)       OSSwapInt64(x) 
#define htonll(x)		OSSwapInt64(x)
#endif

#else
#include <TargetConditionals.h>

#ifdef	TARGET_RT_LITTLE_ENDIAN
#ifndef	ntohll
#define ntohll(x)        OSSwapInt64(x) 
#endif
#ifndef htonll
#define htonll(x)        OSSwapInt64(x)  
#endif
#else 
#ifdef TARGET_RT_BIG_ENDIAN
#ifndef nothll
#define ntohll(x)        ((uint64_t)(x))
#endif
#ifndef htonll
#define htonll(x)        ((uint64_t)(x))
#endif
#else
#error unknown endianness
#endif
#endif
#endif


@implementation UMUtil

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

#if 0
+(void) appendULLToNSMutableData:(NSMutableData *)dat withValue: (unsigned long long) value usingEncoding:(int)encodingVariant
{
	unsigned long long	L64;
	uint32_t		L32;
	uint8_t			L8;

	if(encodingVariant == 0)
	{
		L32=htonl((uint32_t)value);
		[dat appendBytes:&L32 length:sizeof(uint32_t)];
		return;
	}
	
	if(encodingVariant == 2)
	{
		L64=htonll(value);
		[dat appendBytes:&L64 length:sizeof(unsigned long long)];
		return;
	}
	if(encodingVariant == 1)
	{
		if(value < (1ULL<<7))
		{
			L8 = value | 0x80; /* highest bit set means its last byte of integer */
			[dat appendBytes:&L8 length:1];
		}
		else if(value < (1ULL<<14))
		{
			L8 = (value >> 7)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value & 0x7F) | 0x80;
			[dat appendBytes:&L8 length:1];
		}
		else if(value < (1ULL<<21))
		{
			L8 = (value >> 14)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 7) & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value & 0x7F) | 0x80;
			[dat appendBytes:&L8 length:1];
		}
		else if(value < (1ULL<<28))
		{
			L8 = (value >> 21)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 14)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 7) & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value & 0x7F) | 0x80;
			[dat appendBytes:&L8 length:1];
		}
		else if(value < (1ULL<< 35))
		{
			L8 = (value >> 28)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 21)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 14)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 7) & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value & 0x7F) | 0x80;
			[dat appendBytes:&L8 length:1];
		}
		else if(value < (1ULL<< 42))
		{
			L8 = (value >> 35)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 28)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 21)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 14)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 7) & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value & 0x7F) | 0x80;
			[dat appendBytes:&L8 length:1];
		}
		else if(value < (1ULL<< 49))
		{
			L8 = (value >> 42)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 35)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 28)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 21)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 14)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 7) & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value & 0x7F) | 0x80;
			[dat appendBytes:&L8 length:1];
		}
		else if(value < (1ULL<< 56))
		{
			L8 = (value >> 49)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 42)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 35)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 28)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 21)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 14)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 7) & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value & 0x7F) | 0x80;
			[dat appendBytes:&L8 length:1];
		}
		else if(value < (1ULL<< 63))
	    {
			L8 = (value >> 56)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 49)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 42)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 35)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 28)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 21)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 14)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 7) & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value & 0x7F) | 0x80;
			[dat appendBytes:&L8 length:1];
		}
		else
		{
			L8 = (value >> 63)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 56)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 49)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 42)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 35)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 28)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 21)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 14)  & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value >> 7) & 0x7F;
			[dat appendBytes:&L8 length:1];
			L8 = (value & 0x7F) | 0x80;
			[dat appendBytes:&L8 length:1];
		}
	}
}

+ (unsigned long long) grabULLFromNSMutableData:(NSMutableData *)dat usingIndex: (int *) idx usingEncoding:(int)encodingVariant
{
	unsigned long long 		L64;
	uint32_t 		L32;
	uint8_t			L8;
	
	int len;
	
	len = [dat length];
	
	if(encodingVariant == 0)
	{
		L32=0;
		if( ((*idx)+sizeof(L32)) < len)
		{
			[dat getBytes:&L32 range: NSMakeRange(*idx,sizeof(L32))];
		}
		
		L64=ntohl(L32);
		*idx += sizeof(L32);
	}
	if(encodingVariant == 2)
	{
		L64=0;
		if( ((*idx)+sizeof(L64)) < len)
		{
			[dat getBytes:&L64 range: NSMakeRange(*idx,sizeof(L64))];
		}
		
		L64=ntohll(L64);
		*idx += sizeof(L64);
	}
	
	else if (encodingVariant==1)
	{
		L64 = 0;
		L8  = 0;
		while(((L8 & 0x80) == 0) && ( *idx < len))
		{
			if( *idx+1 < len)
				[dat getBytes:&L8 range: NSMakeRange(*idx,1)];
			L64 = L64 << 7;
			L64 = L64 | (L8 & 0x7F);
			(*idx)++;
		}
	}
	return L64;
}
#endif


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

+ (NSString *) release
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


+ (NSString *)getMacAddr: (char *)ifname
{
    struct ifaddrs   *ifaphead = NULL;
    unsigned char *   if_mac = NULL;
    int               found = 0;
    struct ifaddrs   *ifap;
    struct sockaddr_dl *sdl = NULL;
	
 	NSString	*s = nil;
	
    if (getifaddrs(&ifaphead) != 0)
    {
        perror("get_if_name: getifaddrs() failed");
        exit(1);
    }
	
    for (ifap = ifaphead; ifap && !found; ifap = ifap->ifa_next)
    {
        if ((ifap->ifa_addr->sa_family) == AF_LINK)
        {
            if (strlen(ifap->ifa_name) == strlen(ifname))
                if (strcmp(ifap->ifa_name,ifname) == 0)
                {
                    found = 1;
                    sdl = (struct sockaddr_dl *)ifap->ifa_addr;
                    if (sdl)
                    {
                        /* I was returning this from a function before converting
                         * this snippet, which is why I make a copy here on the heap */
                        if_mac = malloc(sdl->sdl_alen);
                        memcpy(if_mac, LLADDR(sdl), sdl->sdl_alen);
                    }
                }
        }
    }
    if (!found)
    {
		s = nil;
    }
    else
    {
        s = [NSString stringWithFormat: @"%02X%02X%02X%02X%02X%02X\n",
                 if_mac[0] , if_mac[1] , if_mac[2] ,
                 if_mac[3] , if_mac[4] , if_mac[5]];
	}
end:
    if(ifaphead)
    {
        freeifaddrs(ifaphead);
    }
    if(if_mac)
    {
        free(if_mac);
        if_mac = NULL;
    }
	 return s;
}

static NSDictionary *   _localMacAddrs = NULL;
static BOOL             _localMacAddrsLoaded = NO;

+ (NSDictionary<NSString *,NSString *>*)getMacAddrs
{
    if(_localMacAddrsLoaded)
    {
        return _localMacAddrs;
    }
    struct ifaddrs   *ifaphead;
    unsigned char *   if_mac;
    int               found = 0;
    struct ifaddrs   *ifap = NULL;
    struct sockaddr_dl *sdl = NULL;
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
            if (ifap->ifa_addr->sa_family == AF_LINK)
            {
                sdl = (struct sockaddr_dl *)ifap->ifa_addr;
                if (sdl)
                {
                    /* I was returning this from a function before converting
                     * this snippet, which is why I make a copy here on the heap */
                //	if_mac = malloc(sdl->sdl_alen);
                    if_mac = (unsigned char *)LLADDR(sdl);
                    NSString *ifname = @(ifap->ifa_name);
                    NSString *macaddr = [NSString stringWithFormat: @"%02X%02X%02X%02X%02X%02X",
                                         if_mac[0],if_mac[1], if_mac[2],if_mac[3],if_mac[4],if_mac[5]];
                    dict[ifname] = macaddr;
                }
            }
        }
        _localMacAddrs = dict;
        freeifaddrs(ifaphead);
        ifaphead = NULL;
    }
    _localMacAddrsLoaded = YES;
    return _localMacAddrs;
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

+ (uint32_t)  random
{
    return arc4random_uniform(UINT_MAX);
}

@end

extern NSString *ulib_get_thread_name(pthread_t thread);

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

