//
//  UMDirtyInteger.h
//  ulib
//
//  Created by Andreas Fink on 04.03.2025.
//

#import <ulib/UMDirtyObject.h>

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

@end


