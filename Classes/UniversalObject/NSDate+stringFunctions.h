//
//  NSDate+stringFunctions.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//
//

#import <Foundation/Foundation.h>
@interface NSDate(stringFunctions)

+ (NSDate *)dateWithStandardDateString:(NSString *)str;
- (NSDate *) dateValue;
- (NSString *)stringValue;

+ (NSString *)zeroDateString;

@end
