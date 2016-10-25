//
//  NSString+UniversalObject.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString *sqlEscapeNSString(NSString *input);

@interface NSString (UniversalObject)
- (NSString *)sqlEscaped;
- (NSData *) unhexedData;
- (NSString *)cquoted;
- (NSString *)printable;
- (NSString *)fileNameRelativeToPath:(NSString *)path;
- (NSString *)prefixLines:(NSString *)prefix;
- (NSString *)stringValue;
- (NSDate *) dateValue;
+ (NSString *)stringWithStandardDate:(NSDate *)d;
- (NSString *)hexString;
- (BOOL)hasCaseInsensitiveSuffix:(NSString *)s;
- (BOOL)hasCaseInsensitivePrefix:(NSString *)p;
@end
