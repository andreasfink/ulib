//
//  UMASN1OctetString.h
//  ulibasn1
//
//  Created by Andreas Fink on 03.07.14.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.



#import <ulib/UMASN1Object.h>

@interface UMASN1OctetString : UMASN1Object

- (UMASN1OctetString *)init;
- (UMASN1OctetString *)initWithValue:(NSData *)d;
- (UMASN1OctetString *)initWithString:(NSString *)s;
- (UMASN1OctetString *)initWithValue:(NSData *)s contentSpecificTag:(int)tag;

- (NSData *) value;
- (void) setValue:(NSData *)s;

@end

