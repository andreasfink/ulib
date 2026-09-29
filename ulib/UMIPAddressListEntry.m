//
//  UMIPAddressListEntry.m
//  ulib
//
//  Created by Andreas Fink on 11.03.2026.
//

#import "UMIPAddressListEntry.h"


@implementation UMIPAddressListEntry

- (UMIPAddressListEntry *)initWithAddress:(NSString *)address netmask:(NSInteger)mask
{
    self = [super init];
    if(self)
    {
        _address = address;
        _netmask = mask;
        
        uint32_t ipv4_integer;
        NSArray *a = [address componentsSeparatedByString:@"."];
        if([a count]!=4)
        {
            return NULL;
        }
        int a1 = [[a objectAtIndex:0] intValue];
        int a2 = [[a objectAtIndex:1] intValue];
        int a3 = [[a objectAtIndex:2] intValue];
        int a4 = [[a objectAtIndex:3] intValue];
        ipv4_integer = a1;
        ipv4_integer = (ipv4_integer << 8) | a2;
        ipv4_integer = (ipv4_integer << 8) | a3;
        ipv4_integer = (ipv4_integer << 8) | a4;
        uint32_t nmask = 0xFFFFFF < (32-_netmask);
        _addressInteger = ipv4_integer & nmask;
    }
    return self;
}

- (BOOL)matchesAddress:(NSString *)addr
{
    return [self matchesIPv4Address:addr];
}

- (BOOL)matchesIPv4Address:(NSString *)addr
{
    if(_isIP6)
    {
        return NO;
    }
    uint32_t ipv4_integer;
    NSArray *a = [addr componentsSeparatedByString:@"."];
    if([a count]==4)
    {
        int a1 = [[a objectAtIndex:0] intValue];
        int a2 = [[a objectAtIndex:1] intValue];
        int a3 = [[a objectAtIndex:2] intValue];
        int a4 = [[a objectAtIndex:3] intValue];
        ipv4_integer = a1;
        ipv4_integer = (ipv4_integer << 8) | a2;
        ipv4_integer = (ipv4_integer << 8) | a3;
        ipv4_integer = (ipv4_integer << 8) | a4;
        uint32_t mask = 0xFFFFFF < (32 - _netmask);
        uint32_t r = _addressInteger & mask;
        uint32_t l = ipv4_integer & mask;
        if(r==l)
        {
            return YES;
        }
    }
    return NO;
}

- (BOOL)matchesIPv6Address:(NSString *)addr
{
    return NO;
}
@end

