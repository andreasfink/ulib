//
//  NSDate+stringFunctions.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import "NSDate+stringFunctions.h"

#define STANDARD_DATE_STRING_FORMAT     @"yyyy-MM-dd HH:mm:ss.SSSSSS"

static NSDateFormatter *_standardDateFormatter = NULL;

@implementation NSDate(stringFunctions)

+(NSDateFormatter *)standardDateFormatter
{
    if(_standardDateFormatter==NULL)
    {
        NSTimeZone *tz = [NSTimeZone timeZoneWithName:@"UTC"];
        NSDateFormatter *sf= [[NSDateFormatter alloc]init];
        NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        [sf setLocale:usLocale];
        [sf setDateFormat:STANDARD_DATE_STRING_FORMAT];
        [sf setTimeZone:tz];
        _standardDateFormatter = sf;
    }
    return _standardDateFormatter;
}

+(NSDate *) dateWithStandardDateString:(NSString *)str
{
    if(str==NULL)
    {
        return [NSDate dateWithTimeIntervalSince1970:0];
    }
    if([str isEqualToString:[NSDate zeroDateString]])
    {
        return [NSDate dateWithTimeIntervalSince1970:0];
    }
    return [[NSDate standardDateFormatter] dateFromString:str];
}

- (NSString *)stringValue
{
    if([self isEqualToDate:[NSDate dateWithTimeIntervalSince1970:0]])
    {
        return [NSDate zeroDateString];
    }
    NSString *s = [[NSDate standardDateFormatter] stringFromDate:self];
    NSTimeInterval ti = [self timeIntervalSinceReferenceDate];
    ti = ti  - (int)ti; /* only fractions */
    int microsecs = ti * 1000000;

    if(microsecs % 1000  == 0) /* if the last 3 digits (microseconds) are all null, we're done */
    {
        return s;
    }
    else
    {
        /* for some reason microseconds are not shown with this date formatter. only miliseconds. */
        /* so we remove last 6 digits and replace it with the real microseconds */
        s = [s substringToIndex:(s.length-6)];
        s = [NSString stringWithFormat:@"%@%06d",s,microsecs];
    }
    return s;
}

- (NSDate *)dateValue
{
    return self;
}

+ (NSString *)zeroDateString
{
    return @"0000-00-00 00:00:00.000000";
}

@end
