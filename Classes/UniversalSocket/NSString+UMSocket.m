//
//  NSString+UMSocket.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import "NSString+UMSocket.h"
#include <arpa/inet.h>
#if defined(FREEBSD)
#include <netinet/in.h>
#endif

@implementation NSString(UMSocket)

- (BOOL)isIPv4
{
    struct in_addr addr4;
    
    int result = inet_pton(AF_INET,self.UTF8String, &addr4);
    if(result==0)
    {
        return NO;
    }
    return YES;
}

- (BOOL)isIPv6
{
    struct in6_addr addr6;

    int result = inet_pton(AF_INET6,self.UTF8String, &addr6);
    if(result==0)
    {
        return NO;
    }
    return YES;
}


- (NSData *)binaryIPaddress4
{
    uint32_t addr4;

    int result = inet_pton(AF_INET,self.UTF8String, (struct in_addr *)&addr4);
    if(result==0)
    {
        addr4 = htonl(addr4);
        return [NSData dataWithBytes:&addr4 length:sizeof(addr4)];
    }
    return 0;
}

- (NSData *)binaryIPaddress6
{
    struct in6_addr addr6;

    int result = inet_pton(AF_INET6,self.UTF8String, &addr6);
    if(result==0)
    {
        return [NSData dataWithBytes:&addr6 length:sizeof(addr6)];
    }
    return 0;
}

@end
