//
//  UMDateWithHistory.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"
#import "UMObjectWithHistory.h"

/*!
 @class UMDateWithHistory
 @brief A NSDate which remembers its previous value and if it has been modified

 UMDateWithHistory is a object holding a NSDate and its previous value.
 It can be used to hold data which is potentially modified at some point in time
 and then remember if it has been modified and what the old values are.
 Used for example in database access to only modify the fields which have changed
 (and if none has changed, not doing any query at all).
 */

@interface UMDateWithHistory : UMObjectWithHistory
{
    
}

- (void)setDate:(NSDate *)newValue;
- (void)setDateFromString:(NSString *)str;

- (NSDate *)date;
- (NSDate *)currentDate;
- (NSDate *)oldDate;

- (NSDate *)nonNullDate;
- (NSDate *)oldNonNullDate;
- (void) loadFromString:(NSString *)str;
- (NSString *)nonNullDateAsString;          /* returns 1970-01-01 00:00:00 if not set */
- (NSString *)oldNonNullDateAsString;       /* returns 1970-01-01 00:00:00 if not set */
- (NSString *)dateAsString; /* returns date or 0000-00-00 00:00:00 if its internally NULL */

+ (NSDate *)zeroDate; /* return zero date  1970-01-01 00:00:00 */
- (BOOL)isNullDate;
+ (BOOL)isNullDate:(NSDate *)date;

@end

