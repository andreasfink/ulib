//
//  UMUUID.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMUUID.h>
#undef uuid_t
#include <unistd.h>

#if defined(FREEBSD)
//#undef uuid_t
#include <uuid.h>
#else
#include <uuid/uuid.h>
#endif

#import <ulib/NSData+UniversalObject.h>

@implementation UMUUID

#ifdef	FREEBSD

+(NSString *)UUID
{ 
    char uuid_string2[40];
    char *uuid_string = & uuid_string2;
    memset(uuid_string2,0x00,40);
    uuid_t uu;
    uint32_t status;
    uuid_create(&uu,&status);
    uuid_to_string(&uu,&uuid_string,&status);

    NSString *uniqueId = NULL;

    time_t              now;
    struct tm           trec;


    time(&now);
    gmtime_r(&now, &trec);
    trec.tm_mon++;
    uniqueId =  [NSString stringWithFormat:@"%04d%02d%02d-%02d%02d%02d-%s",
                 trec.tm_year+1900,
                 trec.tm_mon,
                 trec.tm_mday,
                 trec.tm_hour,
                 trec.tm_min,
                 trec.tm_sec,
                 uuid_string];
    return uniqueId;
}

#else

+(NSString *)UUID
{
    uuid_t uu;
    char uuid_string[40];
    memset(uuid_string,0x00,40);

    char uuid_string2[40];
    memset(uuid_string,0x00,40);

    uuid_generate(uu);
    uuid_unparse(uu,&uuid_string[0]);
    int j=0;
    for(int i=0;i<40;i++)
    {
        if(uuid_string[i]!='-')
        {
            uuid_string2[j++]=uuid_string[i];
        }
    }

    NSString *uniqueId = NULL;

    time_t              now;
    struct tm           trec;

    time(&now);
    gmtime_r(&now, &trec);
    trec.tm_mon++;
    uniqueId =  [NSString stringWithFormat:@"%04d%02d%02d-%02d%02d%02d-%s",
                 trec.tm_year+1900,
                 trec.tm_mon,
                 trec.tm_mday,
                 trec.tm_hour,
                 trec.tm_min,
                 trec.tm_sec,
                 uuid_string2];
    uuid_clear(uu);
    return uniqueId;
}
#endif


+(NSString *)UUID16String
{
    return [[UMUUID UUID16] hexString];
    
}

+(NSData *)UUID16
{
    uuid_t uu;
#ifdef FREEBSD
    uint32_t status;
    uuid_create(&uu,&status);
#else
    uuid_generate(uu);
#endif
    NSData *d = [NSData dataWithBytes:&uu length:sizeof(uu)];
    return d;
}

@end
