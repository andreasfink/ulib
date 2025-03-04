//
//  UMDirtyDouble.h
//  ulib
//
//  Created by Andreas Fink on 04.03.2025.
//

#import <ulib/ulib.h>

@interface UMDirtyDouble : UMDirtyObject

- (UMDirtyDouble *)initWithNumber:(NSNumber *)n;
- (UMDirtyDouble *)initWithDouble:(double)d;
- (UMDirtyDouble *)initWithString:(NSString *)s;

- (NSNumber *)number;
- (void)setNumber:(NSNumber *)n;

- (double)doubleValue;
- (void)setDoubleValue:(double)newValue;

- (NSString *)stringValue;
- (void)setStringValue:(NSString *)s;


@end

