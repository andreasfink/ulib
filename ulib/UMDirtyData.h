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
- (void)setData:(NSData *)d;

- (NSString *)stringValue;
- (void)setStringValue:(NSString *)s;

@end
