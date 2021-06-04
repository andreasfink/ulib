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
#ifdef LINUX
    static NSDate *dateFromStringMktime(NSString *str);
#else
    static NSDate *dateFromStringNSCalendar(NSString *str, const char *ctimezone_str);
#endif

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


+ (NSDate *) dateWithStandardDateString:(NSString *)str
{
    if( (str==NULL) ||
       ([str isEqualToString:@"0000-00-00 00:00:00.000000 UTC"]) ||
       ([str isEqualToString:@"0000-00-00 00:00:00.000 UTC"]) ||
       ([str isEqualToString:@"0000-00-00 00:00:00.000000"]) ||
       ([str isEqualToString:@"0000-00-00 00:00:00.000"]) ||
       ([str isEqualToString:@"0000-00-00 00:00:00"]) ||
       ([str isEqualToString:@""]) ||
       [str isEqualToString:[NSDate zeroDateString]])
    {
        return [NSDate dateWithTimeIntervalSince1970:0];
    }
    
#ifdef LINUX
    return dateFromStringMktime(str);
#else
    return dateFromStringNSCalendar(str,"UTC");
#endif
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

#ifdef LINUX
static NSDate *dateFromStringMktime(NSString *str)
{
    struct tm tm;
    memset (&tm,0x00, sizeof(tm));
    const char *cdate_str ="";
    const char *ctime_str = "";
    const char *ctimezone_str = "UTC";
    NSArray *components = [str componentsSeparatedByString:@" "];
    if(components.count >0)
    {
        NSString *s = components[0];
        cdate_str = s.UTF8String;
    }
    if(components.count > 1)
    {
        NSString *s = components[1];
        ctime_str = s.UTF8String;
    }
    if(components.count > 2)
    {
        NSMutableArray *arr =  [components mutableCopy];
        [arr removeObjectsInRange:NSMakeRange(0,2)];
        NSString *s = [arr componentsJoinedByString:@" "];
        ctimezone_str = s.UTF8String;
    }

    /* parsing date */
    sscanf(cdate_str,"%04d-%02d-%02d",
           &tm.tm_year,
           &tm.tm_mon,
           &tm.tm_mday);
    tm.tm_year  -= 1900;
    tm.tm_mon -= 1;
    
    /* we expect the timestamp to be in UTC so no daylight savings time and GMT offset 0 */
    tm.tm_isdst = -1;
    tm.tm_gmtoff = 0;
    double subsecond=0;
    if(strlen(ctime_str) ==8 ) /* HH:mm:ss.SSSSSS */
    {
        sscanf(ctime_str,"%02d:%02d:%02d",
               &tm.tm_hour,
               &tm.tm_min,
               &tm.tm_sec);
    }
    else if(strlen(ctime_str) >=9  ) /* HH:mm:ss.SSSSSS */
    {
        double sec = 0;
        sscanf(ctime_str,"%02d:%02d:%lf",
               &tm.tm_hour,
               &tm.tm_min,
               &sec);
        tm.tm_sec = (int)sec;
        subsecond = sec - floor(sec);
    }
    else
    {
        return NULL;
    }
    tm.tm_zone = (char *)ctimezone_str;
    
    
    const char *tzstring = getenv("TZ");
    if((tzstring==NULL) || (strncmp("UTC",tzstring,3)!=0))
    {
        setenv("TZ","UTC",1);
    }
    time_t t = mktime(&tm);
    if(t==-1)
    {
        return NULL;
    }
    NSTimeInterval ti = (double)t + subsecond;
    return [NSDate dateWithTimeIntervalSince1970:ti];
}

#else

static NSDate *dateFromStringNSCalendar(NSString *str, const char *ctimezone_str)
{
    int year;
    int month;
    int day;
    int hour;
    int minute;
    int seconds;
    double subsecond = 0;
    const char *cdate_str="";
    const char *ctime_str="";
    
    if( (str==NULL) ||
       ([str isEqualToString:@"0000-00-00 00:00:00.000000 UTC"]) ||
       ([str isEqualToString:@"0000-00-00 00:00:00.000 UTC"]) ||
       ([str isEqualToString:@"0000-00-00 00:00:00.000000"]) ||
       ([str isEqualToString:@"0000-00-00 00:00:00.000"]) ||
       ([str isEqualToString:@"0000-00-00 00:00:00"]) ||
       ([str isEqualToString:@""]))
    {
        return [NSDate dateWithTimeIntervalSince1970:0];
    }
    
    NSArray *components = [str componentsSeparatedByString:@" "];
    if(components.count >0)
    {
        NSString *s = components[0];
        cdate_str = s.UTF8String;
    }
    if(components.count > 1)
    {
        NSString *s = components[1];
        ctime_str = s.UTF8String;
    }
    if(components.count > 2)
    {
        NSMutableArray *arr =  [components mutableCopy];
        [arr removeObjectsInRange:NSMakeRange(0,2)];
        NSString *s = [arr componentsJoinedByString:@" "];
        ctimezone_str = s.UTF8String;
    }

    /* parsing date */
    sscanf(cdate_str,"%04d-%02d-%02d",
           &year,
           &month,
           &day);
    if(strlen(ctime_str) ==8 ) /* HH:mm:ss.SSSSSS */
    {
        sscanf(ctime_str,"%02d:%02d:%02d",
               &hour,
               &minute,
               &seconds);
    }
    else if(strlen(ctime_str) >=9  ) /* HH:mm:ss.SSSSSS */
    {
        sscanf(ctime_str,"%02d:%02d:%lf",
               &hour,
               &minute,
               &subsecond);
        seconds = (int)subsecond;
        subsecond = subsecond - (double)seconds;
    }
    else
    {
        return NULL;
    }
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.day = day;
    dateComponents.month = month;
    dateComponents.year = year;
    dateComponents.hour = hour;
    dateComponents.minute = minute;
    dateComponents.second = seconds;
#ifdef __APPLE__
    dateComponents.nanosecond = subsecond * 1000000000;
#endif
    if(ctimezone_str!=NULL)
    {
        NSTimeZone *tz      = [NSTimeZone timeZoneWithName:@(ctimezone_str)];
        dateComponents.timeZone = tz;
    }
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDate *date = [gregorianCalendar dateFromComponents:dateComponents];
    return date;
}

#endif
