//
//  UMDirtyData.h
//  ulib
//
//  Created by Andreas Fink on 04.03.2025.
//

#import <ulib/UMDirtyObject.h>

@interface UMDirtyData : UMDirtyObject


- (UMDirtyData *)initWithData:(NSData *)d;
- (UMDirtyData *)initWithString:(NSString *)s;

- (NSData *)data;
- (NSData *)previousData;
- (void)setData:(NSData *)d;

- (NSString *)stringValue;
- (NSString *)previousStringValue;
- (void)setStringValue:(NSString *)s;

- (UMDirtyData *)copyWithZone:(NSZone *)zone;

@end
