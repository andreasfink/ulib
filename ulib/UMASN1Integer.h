//
//  UMASN1Integer.h
//  ulibasn1
//
//  Created by Andreas Fink on 03.07.14.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.


#import <ulib/UMASN1Object.h>
#import <ulib/UMASN1ObjectPrimitive.h>


@interface UMASN1Integer : UMASN1ObjectPrimitive

- (UMASN1Integer *)initWithValue:(int64_t)i;
- (UMASN1Integer *)initWithNumber:(NSNumber *)num;

- (int64_t) value;
- (void) setValue:(int64_t)v;
- (UMASN1Integer *)initWithString:(NSString *)s;
- (NSNumber *)number;

@end
