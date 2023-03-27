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
- (NSString *)onlyHex;      /*!< filters the string to only include hex chars and converts to uppercase */
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
- (NSData *)sha1;
- (BOOL)webBoolValue;
- (NSString *)trim;
- (NSInteger)intergerValueSupportingHex;

/* this is used to clean names. They are all returned in lowercase
  only lowercase is allowed. Uppercase is converted
  . is not allowed in first place
  Allowed punctioations are - _ + , = %
*/
- (NSString *)filterNameWithMaxLength:(int)maxlen;
- (NSString *)randomizeX;

@end
