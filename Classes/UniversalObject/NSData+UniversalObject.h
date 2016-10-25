//
//  NSData+UniversalObject.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (UniversalObject) 

- (NSString *) hexString;
- (NSData *) hex;
- (unsigned long) crc;
- (NSData *)unhexedData;
@end

@interface NSMutableData (UniversalObject)
- (void) appendByte:(uint8_t)byte;

@end
