//
//  NSData+ulib.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>

#if defined(LINUX) || defined(FREEBSD)
/* this stuff is not in Gnustep but in OSX so we emulate it here */
#import <Foundation/Foundation.h>
typedef NSUInteger NSDataSearchOptions;
#define  NSDataSearchBackwards (1UL << 0)
#define  NSDataSearchAnchored (1UL << 1)
#endif

@interface NSData(ulib)

- (NSString *)hierarchicalDescriptionWithPrefix:(NSString *)prefix; /*!< convert a NSData to a string in a human readable fashion with identation (prefix) being properly handled */
- (NSString *)stringForDumping;
- (NSString *)dump;
- (NSString *)hexString;   /*!< hex NSString representation of a NSData */
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
- (NSString *)encodeBase64;
- (NSString *)urlencode;
- (NSString *)stringValue;
- (NSRange) rangeOfData_dd:(NSData *)dataToFind;
- (NSRange) rangeOfData_dd:(NSData *)dataToFind startingFrom:(long)i;

@end


