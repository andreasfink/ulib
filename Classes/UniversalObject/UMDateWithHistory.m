//
//  UMDateWithHistory.m
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#include <time.h>

#import "UMDateWithHistory.h"
#import "NSDate+stringFunctions.h"
#import "NSString+UniversalObject.h"

#define UMDATE_FORMAT   @"%Y-%m-%d %H:%M:%S.%F UTC"
#define UMDATE_FORMAT_C   "%Y-%m-%d %H:%M:%S.%F UTC"
//#define UMDATE_NULL     @"0001-01-01 00:00:00"

@implementation UMDateWithHistory
@synthesize oldValue;
@synthesize currentValue;

- (id)init
{
    self = [super init];
    if (self)
    {
        // Initialization code here.
        self.oldValue = [UMDateWithHistory zeroDate];
        self.currentValue = [UMDateWithHistory zeroDate];
    }
    
    return self;
}


-(void)setDate:(NSDate *)newValue
{
    if(newValue==NULL)
    {
        newValue = [UMDateWithHistory zeroDate];
    }
    
    oldValue = currentValue;
    currentValue = newValue;
    if(currentValue != oldValue)
    {
        isModified = YES;
    }
}

- (NSDate *)date
{
    return currentValue;
}

-(NSDate *)oldDate
{
    return oldValue;
}

-(NSString *)nonNullDateAsString
{
    NSString *s;
    if(currentValue==NULL)
    {
        currentValue = [UMDateWithHistory zeroDate];
    }

    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    s = [dateFormatter stringFromDate:currentValue];
    return s;
}

+ (NSDate *)zeroDate
{
    /* this returns 1970-01-01 00:00:00 */
    return [NSDate dateWithTimeIntervalSince1970:0];
}

- (BOOL)isNullDate
{
    if(currentValue==NULL)
        return YES;
    return [UMDateWithHistory isNullDate:currentValue];
}

+ (BOOL)isNullDate:(NSDate *)d
{
    if([d isEqualToDate:[UMDateWithHistory zeroDate]])
    {
        return YES;
    }
    return NO;
    
}


-(NSString *)oldNonNullDateAsString
{
    NSString *s;
    if(oldValue==NULL)
    {
        oldValue = [UMDateWithHistory zeroDate];
    }
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    s = [dateFormatter stringFromDate:oldValue];

    return s;
}

-(NSDate *)nonNullDate
{
    if(currentValue==NULL)
    {
        currentValue = [UMDateWithHistory zeroDate];
    }
    return currentValue;
}

- (NSDate *)oldNonNullDate;
{
    if(oldValue==NULL)
    {
        oldValue = [UMDateWithHistory zeroDate];
    }
    return oldValue;
}



- (BOOL) hasChanged
{
    return isModified;
}

- (void) clearChangedFlag;
{
    isModified = NO;
}

- (void)clearDirtyFlag
{
    self.oldValue = self.currentValue;
    [self clearChangedFlag];
}

///NS_CALENDAR_DEPRECATED(10_4, 10_10, 2_0, 8_0, "Use NSCalendar and NSDateComponents and NSDateFormatter instead")

- (void) loadFromString:(NSString *)str
{
    self.currentValue = [str dateValue];
}

- (NSString *)description
{
    if(isModified)
    {
        return [NSString stringWithFormat:@"Date '%@' (unmodified)",currentValue];
    }
    else
    {
        return [NSString stringWithFormat:@"Date '%@' (changed from '%@')",currentValue,oldValue];
    }
}

@end
