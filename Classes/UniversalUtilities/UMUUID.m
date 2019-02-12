//
//  UMUUID.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMUUID.h"
#include <unistd.h>

#if defined(FREEBSD)
#include <sys/uuid.h>
#else
#include <uuid/uuid.h>
#endif

@implementation UMUUID

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

@end
