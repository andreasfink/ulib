//
//  UMDateWithHistory.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#include <time.h>

#import "UMDateWithHistory.h"
#import "NSDate+stringFunctions.h"
#import "NSString+UniversalObject.h"

#define UMDATE_FORMAT   @"%Y-%m-%d %H:%M:%S.%F UTC"
#define UMDATE_FORMAT_C   "%Y-%m-%d %H:%M:%S.%F UTC"
#define UMDATE_ZERO   @"0000-00-00 00:00.000000"

#define UMDATE_STRING_FORMAT  @"yyyy-MM-dd HH:mm:ss.SSSSSS"

static NSDateFormatter *umdate_string_formatter = NULL;

@implementation UMDateWithHistory

- (id)init
{
    self = [super init];
    if (self)
    {
        // Initialization code here.
        self.oldValue       = [UMDateWithHistory zeroDate];
        self.currentValue   = [UMDateWithHistory zeroDate];
        if(umdate_string_formatter==NULL)
        {
            NSDateFormatter* umdate_string_formatter = [[NSDateFormatter alloc] init];
            [umdate_string_formatter setDateFormat:UMDATE_STRING_FORMAT];
        }
    }
    return self;
}


-(void)setDate:(NSDate *)newValue
{
    if(newValue==NULL)
    {
        newValue = [UMDateWithHistory zeroDate];
    }
    
    _oldValue = _currentValue;
    _currentValue = newValue;

    NSDate *currentDate = (NSDate *)_currentValue;
    NSDate *oldDate     = (NSDate *)_oldValue;
    if([currentDate isEqualToDate:oldDate])
    {
        _isModified = YES;
    }
    else
    {
        _isModified = NO;
    }
}

- (NSDate *)date
{
    return [self currentDate];
}


- (NSDate *)currentDate
{
    return (NSDate *)_currentValue;
}

-(NSDate *)oldDate
{
    return (NSDate *)_oldValue;
}

-(NSString *)nonNullDateAsString
{
    NSString *s;
    if(_currentValue==NULL)
    {
        _currentValue = [UMDateWithHistory zeroDate];
    }
    s = [umdate_string_formatter stringFromDate:(NSDate *)_currentValue];
    return s;
}

-(NSString *)dateAsString
{
    if(_currentValue==NULL)
    {
        return UMDATE_ZERO;
    }

    NSString *s = [umdate_string_formatter stringFromDate:(NSDate *)_currentValue];
    return s;
}

- (void)setDateFromString:(NSString *)str
{
    if(([str isEqualToString:UMDATE_ZERO]) || (str.length == 0))
    {
        self.currentValue = NULL;
    }
    else
    {
        NSDate *d = [umdate_string_formatter dateFromString:str];
        self.currentValue = d;
    }
}

+ (NSDate *)zeroDate
{
    /* this returns 1970-01-01 00:00:00 */
    return [NSDate dateWithTimeIntervalSince1970:0];
}

- (BOOL)isNullDate
{
    if(_currentValue==NULL)
        return YES;
    return NO;
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
    if(_oldValue==NULL)
    {
        _oldValue = [UMDateWithHistory zeroDate];
    }
    s = [umdate_string_formatter stringFromDate:(NSDate *)_oldValue];
    return s;
}

-(NSDate *)nonNullDate
{
    if(_currentValue==NULL)
    {
        _currentValue = [UMDateWithHistory zeroDate];
    }
    return (NSDate *)_currentValue;
}

- (NSDate *)oldNonNullDate;
{
    if(_oldValue==NULL)
    {
        _oldValue = [UMDateWithHistory zeroDate];
    }
    return (NSDate *)_oldValue;
}



- (void) loadFromString:(NSString *)str
{
    self.currentValue = [str dateValue];
}

- (NSString *)description
{
    if(_isModified)
    {
        NSDate *currentDate = (NSDate *)_currentValue;
        return [NSString stringWithFormat:@"Date '%@' (unmodified)",currentDate];
    }
    else
    {
        NSDate *currentDate = (NSDate *)_currentValue;
        NSDate *oldDate     = (NSDate *)_oldValue;
        return [NSString stringWithFormat:@"Date '%@' (changed from '%@')",currentDate,oldDate];
    }
}

@end
