//
//  UMDateWithHistory.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#import "UMObject.h"

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

