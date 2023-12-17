//
//  NSMutableData+ulib.h
//  ulib
//
//  Created by Andreas Fink on 23.10.12.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSMutableData (ulib)

- (void)binaryToBase64;
- (void)stripBlanks;
- (BOOL)blankAtBeginning:(int)start;
- (BOOL)blankAtEnd:(int)end;
- (void) appendByte:(uint8_t)byte; /*!< add  a single byte to a NSData object */
@end
