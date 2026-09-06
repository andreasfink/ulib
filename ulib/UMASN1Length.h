//
//  UMASN1Length.h
//  ulibasn1
//
//  Created by Andreas Fink on 03.07.14.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.


#import <ulib/ulib.h>

@interface UMASN1Length : UMObject
{
    uint64_t    length;
    BOOL        undefinedLength;
}
@property (readwrite,assign) BOOL undefinedLength;

- (void)setLength:(uint64_t)length;
- (uint64_t)length;

- (NSData *)berEncoded;
- (NSData *)berEncodedEndOfData;


//- (void)appendToMutableData:(NSMutableData *)d;
- (UMASN1Length *)initWithBerData:(NSData *)data atPosition:(NSUInteger *)pos context:(id)context;
@end
