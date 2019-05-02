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
    if(standardDateFormatter==NULL)
    {
        standardDateFormatter= [[NSDateFormatter alloc]init];
        [standardDateFormatter setDateFormat:STANDARD_DATE_STRING_FORMAT];
    }
    return [standardDateFormatter dateFromString:str];
}

- (NSString *)stringValue
{
    if([self isEqualToDate:[NSDate dateWithTimeIntervalSince1970:0]])
    {
        return [NSDate zeroDateString];
    }

    if(standardDateFormatter==NULL)
    {
        standardDateFormatter= [[NSDateFormatter alloc]init];
        [standardDateFormatter setDateFormat:STANDARD_DATE_STRING_FORMAT];
    }
    return [standardDateFormatter stringFromDate:self];
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
