//
//  UMDirtyString.h
//  ulib
//
//  Created by Andreas Fink on 04.03.2025.
//

#import <ulib/UMDirtyObject.h>

#define UMDIRTY_STRING(a)     [[UMDirtyString alloc]initWithString:a]

@interface UMDirtyString : UMDirtyObject

- (UMDirtyString *)initWithString:(NSString *)s;
- (NSString *)stringValue;
- (void)setStringValue:(NSString *)s;

- (UMDirtyString *)copyWithZone:(NSZone *)zone;

@end


