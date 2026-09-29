//
//  UMIPAddressListEntry.h
//  ulib
//
//  Created by Andreas Fink on 11.03.2026.
//

#import <ulib/UMObject.h>


@interface UMIPAddressListEntry : UMObject
{
    NSString    *_address;
    uint32_t    _addressInteger;

    NSInteger   _netmask;
    BOOL        _isIP6;
}

@property(readwrite,strong,atomic)     NSString    *address;
@property(readwrite,assign,atomic)     uint32_t    addressInteger;
@property(readwrite,assign,atomic)     NSInteger   netmask;
@property(readwrite,assign,atomic)     BOOL        isIP6;

- (UMIPAddressListEntry *)initWithAddress:(NSString *)address netmask:(NSInteger)mask;

- (BOOL)matchesAddress:(NSString *)addr;
- (BOOL)matchesIPv4Address:(NSString *)addr;
- (BOOL)matchesIPv6Address:(NSString *)addr;


@end

