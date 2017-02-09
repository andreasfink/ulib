//
//  NSString+UniversalObject.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>

NSString *sqlEscapeNSString(NSString *input);

@interface NSString (UniversalObject)
- (NSString *)sqlEscaped;   /*!< escape characters for SQL */
- (NSData *) unhexedData;   /*!< convert a hex string to NSData */
- (NSString *)cquoted;      /*!< enquote C style */
- (NSString *)printable;    /*!< only printable chars please */
- (NSString *)fileNameRelativeToPath:(NSString *)path;
- (NSString *)prefixLines:(NSString *)prefix;   /*!< prefix all lines in a string (useful for identation) */
- (NSString *)stringValue;                      /*!< returns self. useful for classes expecting any type of object and always want to convert to string */
- (NSDate *) dateValue;                         /*!< convert to date while assuming standard format */
+ (NSString *)stringWithStandardDate:(NSDate *)d;   /*!< convert from date while assuming standard format */
- (NSString *)hexString;                            /*!< convert string to hex string */
- (BOOL)hasCaseInsensitiveSuffix:(NSString *)s;     /*!< does it end with this suffix in a case insensitive way */
- (BOOL)hasCaseInsensitivePrefix:(NSString *)p;     /*!< does it start with this prefix in a case insensitive way */

- (BOOL)isEqualToStringCaseInsensitive:(NSString *)aString;

@end
