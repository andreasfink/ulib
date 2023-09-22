//
//  NSData+UniversalObject.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (UniversalObject) 

- (NSString *) hexString;   /*!< hex NSString representation of a NSData */
- (NSData *) hex;           /*!< hex NSData representation of a NSData */
- (unsigned long) crc;      /*!< calculate the CRC of a NSData */
- (NSData *)unhexedData;    /*!< convert a NSData object of hex bytes into their binary version */
- (NSData *)sha1;           /*!< calculates the sha1 hash of the data */
- (NSData *)sha224;         /*!< calculates the sha224 hash of the data */
- (NSData *)sha256;         /*!< calculates the sha256 hash of the data */
- (NSData *)sha384;         /*!< calculates the sha384 hash of the data */
- (NSData *)sha512;         /*!< calculates the sha512 hash of the data */
- (NSData *)xor:(NSData *)xxor;
- (NSString *)utf8String;
@end

@interface NSMutableData (UniversalObject)
- (void) appendByte:(uint8_t)byte; /*!< add  a single byte to a NSData object */

@end
