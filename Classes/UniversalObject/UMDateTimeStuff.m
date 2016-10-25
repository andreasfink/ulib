//
//  UMDateTimeStuff.m
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//
//

#import "UMDateTimeStuff.h"
#include <time.h>


NSString *UMTimeStampDTfromTime(time_t current)
{
    struct tm trec;
    gmtime_r(&current, &trec);
    NSString *s = [NSString stringWithFormat:@"%04d-%02d-%02d %02d:%02d:%02d.000000",
                   trec.tm_year+1900,
                   trec.tm_mon+1,
                   trec.tm_mday,
                   trec.tm_hour,
                   trec.tm_min,
                   trec.tm_sec];
    return s;
}

time_t UMTimeFromTimestampDT(NSString *timestamp)
{
    char ts[256];
    struct tm trec;
    
    if(timestamp==NULL)
    {
        return 0;
    }
    if([timestamp isEqualToString:@""])
    {
        return 0;
    }
    if([timestamp isEqualToString:@"0000-00-00 00:00:00.000000"])
    {
        return 0;
    }
    if([timestamp isEqualToString:@"0000-00-00 00:00:00"])
    {
        return 0;
    }
    
    strncpy(ts, timestamp.UTF8String,255),
    ts[20] = '\0';
    
    sscanf(ts,"%04d-%02d-%02d %02d:%02d:%02d",
           &trec.tm_year,
           &trec.tm_mon,
           &trec.tm_mday,
           &trec.tm_hour,
           &trec.tm_min,
           &trec.tm_sec);
    trec.tm_year = trec.tm_year -1900;
    trec.tm_mon = trec.tm_mon -1;
    time_t t = timegm(&trec);
    return t;
}

NSString *UMTimeStampDT(void)
{
    time_t current;
    time(&current);
    NSString *result;
    result = UMTimeStampDTfromTime(current);
    return result;
}

NSString *UMTimeStampDTLocal(void)
{
    time_t  current;
    struct tm trec;
    
    time(&current);
    localtime_r(&current,&trec);
    NSString *s = [NSString stringWithFormat:@"%04d-%02d-%02d %02d:%02d:%02d",
                   trec.tm_year+1900,
                   trec.tm_mon+1,
                   trec.tm_mday,
                   trec.tm_hour,
                   trec.tm_min,
                   trec.tm_sec];
    return s;	
}
