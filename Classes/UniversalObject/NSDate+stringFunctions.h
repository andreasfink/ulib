//
//  NSDate+stringFunctions.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import <Foundation/Foundation.h>
@interface NSDate(stringFunctions)

+ (NSDate *)dateWithStandardDateString:(NSString *)str; /*!< convert the date from the standard format (yyyy-MM-dd HH:mm:ss.SSSS) to a NSDate object */
- (NSDate *) dateValue; /*!< returns self. useful for methods who accept id and internally always want to use a date at the end even if you already pass a date */
- (NSString *)stringValue;  /*!< returns a string representation. returns 0000-00-00 00:00:00.000000 instead of 1970-01-0100:00:00.000000 for a value of 0 */

+ (NSString *)zeroDateString; /*!< returns 0000-00-00 00:00:00.000000 */

@end
