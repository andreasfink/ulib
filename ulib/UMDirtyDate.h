//
//  UMDirtyDate.h
//  ulib
//
//  Created by Andreas Fink on 04.03.2025.
//

#import <ulib/UMDirtyObject.h>


@interface UMDirtyDate : UMDirtyObject

- (UMDirtyDate *)initWithDate:(NSDate *)d;
- (UMDirtyDate *)initWithString:(NSString *)s;

- (NSDate *)date;
- (NSDate *)previousDate;
- (void)setDate:(NSDate *)d;

- (NSString *)stringValue;
- (NSString *)previousStringValue;
- (void)setStringValue:(NSString *)s;

@end

