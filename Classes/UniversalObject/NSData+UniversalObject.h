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
@end

@interface NSMutableData (UniversalObject)
- (void) appendByte:(uint8_t)byte; /*!< add  a single byte to a NSData object */

@end
