//
//  UMASN1BitString.h
//  ulibasn1
//
//  Created by Andreas Fink on 03.07.14.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulibasn1/UMASN1Object.h>

@interface UMASN1BitString : UMASN1Object
{
    NSDictionary *_bitStringDefintionBitToName; /* dictionary @(number)->stringValue  */
    NSDictionary *_bitStringDefintionNameToBit; /* dictionary stringValue -> @(number) */
}


- (UMASN1BitString *)initWithValue:(NSData *)d bitcount:(NSInteger)bc;
- (void)setBitStringDefinition;     /* this is overridden normally */

- (id)objectValue;

- (void)setBit:(NSInteger)bit value:(BOOL)bitValue;
- (void)setBit:(NSInteger)bit;
- (void)clearBit:(NSInteger)bit;
- (BOOL)bit:(NSInteger)bit;
@end
