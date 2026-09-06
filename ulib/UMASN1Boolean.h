//
//  UMASN1Boolean.h
//  ulibasn1
//
//  Created by Andreas Fink on 03.07.14.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulibasn1/UMASN1Object.h>

@interface UMASN1Boolean : UMASN1Object

- (UMASN1Boolean *)initWithValue:(BOOL)value;
- (UMASN1Boolean *)initAsYes;
- (UMASN1Boolean *)initAsNo;
- (BOOL)isTrue;
- (BOOL)isFalse;
- (void)setValue:(BOOL)v;
@end
