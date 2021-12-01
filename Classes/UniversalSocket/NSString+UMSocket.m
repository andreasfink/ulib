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
    if([self hasPrefix:@"ipv4:"])
    {
        return YES;
    }
    struct in_addr addr4;
    
    int result = inet_pton(AF_INET,self.UTF8String, &addr4);
    if(result==1)
    {
        return YES;
    }
    return NO;
}

- (BOOL)isIPv6
{
    if([self hasPrefix:@"ipv6:"])
    {
        return YES;
    }

    struct in6_addr addr6;

    int result = inet_pton(AF_INET6,self.UTF8String, &addr6);
    if(result==1)
    {
        return YES;
    }
    return NO;
}


- (NSData *)binaryIPAddress
{
    if([self isIPv4])
    {
        return [self binaryIPAddress4];
    }
    return [self binaryIPAddress6];
}

- (NSData *)binaryIPAddress4
{
    uint32_t addr4;

    int result = inet_pton(AF_INET,self.UTF8String, (struct in_addr *)&addr4);
    if(result==1)
    {
        return [NSData dataWithBytes:&addr4 length:sizeof(addr4)];
    }
    return 0;
}

- (NSData *)binaryIPAddress6
{
    struct in6_addr addr6;

    int result = inet_pton(AF_INET6,self.UTF8String, &addr6);
    if(result==1)
    {
        return [NSData dataWithBytes:&addr6 length:sizeof(addr6)];
    }
    return 0;
}

@end
