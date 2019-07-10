//
//  NSDate+stringFunctions.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import "NSDate+stringFunctions.h"

#define STANDARD_DATE_STRING_FORMAT     @"yyyy-MM-dd HH:mm:ss.SSSSSS"

static NSDateFormatter *standardDateFormatter = NULL;

@implementation NSDate(stringFunctions)

+(NSDateFormatter *)standardDateFormatter
{
    if(standardDateFormatter==NULL)
    {
        NSTimeZone *tz = [NSTimeZone timeZoneWithName:@"UTC"];
        standardDateFormatter= [[NSDateFormatter alloc]init];
        NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        [standardDateFormatter setLocale:usLocale];
        [standardDateFormatter setDateFormat:STANDARD_DATE_STRING_FORMAT];
        [standardDateFormatter setTimeZone:tz];
    }
    return standardDateFormatter;
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
    return [[NSDate standardDateFormatter] stringFromDate:self];
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
