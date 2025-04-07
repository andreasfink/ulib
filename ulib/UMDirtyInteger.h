//
//  UMDirtyInteger.h
//  ulib
//
//  Created by Andreas Fink on 04.03.2025.
//

#import <ulib/UMDirtyObject.h>

#define UMDIRTY_INTEGER(a)    [[UMDirtyInteger alloc]initWithInteger:a]

@interface UMDirtyInteger : UMDirtyObject
{
    
}

- (UMDirtyInteger *)initWithNumber:(NSNumber *)n;
- (UMDirtyInteger *)initWithInteger:(NSInteger)i;
- (UMDirtyInteger *)initWithString:(NSString *)s;

- (NSNumber *)number;
- (NSNumber *)previousNumber;
- (void)setNumber:(NSNumber *)n;

- (NSInteger)integerValue;
- (NSInteger)previousIntegerValue;
- (void)setIntegerValue:(NSInteger)newValue;

- (NSString *)stringValue;
- (NSString *)previousStringValue;
- (void)setStringValue:(NSString *)s;

- (UMDirtyInteger *)copyWithZone:(NSZone *)zone;

@end

