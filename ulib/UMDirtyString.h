//
//  UMDirtyString.h
//  ulib
//
//  Created by Andreas Fink on 04.03.2025.
//

#import <ulib/UMDirtyObject.h>

@interface UMDirtyString : UMDirtyObject

- (UMDirtyString *)initWithString:(NSString *)s;
- (NSString *)stringValue;
- (void)setStringValue:(NSString *)s;

@end


