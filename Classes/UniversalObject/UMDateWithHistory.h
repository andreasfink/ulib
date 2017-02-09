//
//  UMDateWithHistory.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"

/*!
 @class UMDateWithHistory
 @brief A NSDate which remembers its previous value and if it has been modified

 UMDateWithHistory is a object holding a NSDate and its previous value.
 It can be used to hold data which is potentially modified at some point in time
 and then remember if it has been modified and what the old values are.
 Used for example in database access to only modify the fields which have changed
 (and if none has changed, not doing any query at all).
 */

@interface UMDateWithHistory : UMObject
{
@private
    NSDate      *oldValue;
    NSDate      *currentValue;
    BOOL        isModified;
}

@property (readwrite,strong) NSDate    *oldValue;
@property (readwrite,strong) NSDate    *currentValue;

- (void)setDate:(NSDate *)newValue;
- (NSDate *)date;
- (NSDate *)oldDate;
- (BOOL) hasChanged;
- (void) clearChangedFlag;
- (NSDate *)nonNullDate;
- (NSDate *)oldNonNullDate;
- (void)clearDirtyFlag;
- (void) loadFromString:(NSString *)str;
- (NSString *)nonNullDateAsString;
- (NSString *)oldNonNullDateAsString;
+ (NSDate *)zeroDate; /* return zero date  1970-01-01 00:00:00 */
- (BOOL)isNullDate;
+ (BOOL)isNullDate:(NSDate *)date;

@end

