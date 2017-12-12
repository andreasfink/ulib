//
//  UMRegex.m
//  ulib
//
//  Created by Andreas Fink on 08.07.16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMRegex.h"
#import "UMRegexMatch.h"

#include <regex.h>

@implementation UMRegex
@synthesize rule;

- (void) dealloc
{
    [self free];
}

- (void)free
{
    if(preg)
    {
        regfree((regex_t *)preg);
        free(preg);
    }
    preg=NULL;

    if(str2)
    {
        free(str2);
    }
    str2=NULL;
}


- (UMRegex *)initWithString:(NSString *)r flags:(int)cflags
{
    if(r==NULL)
    {
        return NULL;
    }
    self = [super init];
    if(self)
    {
        rule = r;
        preg = malloc(sizeof(regex_t));
        memset(preg,0x00,sizeof(regex_t));
        const char *str = [r cStringUsingEncoding:NSASCIIStringEncoding];
        if(str2)
        {
            free(str2);
            str2=NULL;
        }
        size_t bufsize = strlen(str)+1;
        str2 = malloc(bufsize);
        memset(str2,0x00,bufsize);
        strncpy (str2,str,bufsize);
        int rc = regcomp((regex_t *)preg,str2,cflags);
        if(rc!=0)
        {
            char buffer[512];
            regerror(rc, (regex_t *)preg, buffer, sizeof(buffer));
            [self free];
            @throw([NSException exceptionWithName:@"INV_REGEX" reason:[NSString stringWithFormat:@"regex compilation for '%s' failed: %s",str,buffer] userInfo:NULL]);
        }
    }
    return self;
}

-(NSArray *)regexExec:(NSString *)string
             maxMatch:(int)max
                flags:(int)eflags
{
    if(string==NULL)
    {
        @throw([NSException exceptionWithName:@"NULL_REGEX" reason:@"regex match against null string" userInfo:NULL]);
    }

    size_t      nmatch = max;
    size_t      msize = sizeof(regmatch_t) * nmatch;
    regmatch_t  *pmatch = malloc(msize);
    memset(pmatch,0x00,msize);
    const char *str = [string cStringUsingEncoding:NSISOLatin1StringEncoding];
    if(str2)
    {
        free(str2);
        str2=NULL;
    }
    size_t bufsize = strlen(str)+1;
    str2 = malloc(bufsize);
    memset(str2,0x00,bufsize);
    strncpy (str2,str,bufsize);

    int rc = regexec((regex_t *)preg, str2,  nmatch, pmatch, eflags);
    if (rc != REG_NOMATCH && rc != 0)
    {
        char buffer[512];
        regerror(rc, (regex_t *)preg, buffer, sizeof(buffer));
        free(pmatch);
        pmatch=NULL;
        @throw([NSException exceptionWithName:@"EXEC_REGEX"
                                       reason:
                [NSString stringWithFormat:@"regex execution on `%s' failed: %s",str,buffer]
                                     userInfo:NULL]);
    }
    if(rc==REG_NOMATCH)
    {
        free(pmatch);
        pmatch=NULL;
        return NULL;
    }
    NSMutableArray *a = [[NSMutableArray alloc]init];
    for(int i=0;i<max;i++)
    {
        regmatch_t *match = &pmatch[i];
        NSString *matched;
        regoff_t start = match->rm_so;
        regoff_t end = match->rm_eo;
        if(start == end)
        {
            matched = @"";
        }
        else
        {
            NSData *d = [NSData dataWithBytes:&str[start] length:(NSUInteger)(end-start)];
            matched = [[NSString alloc]initWithData:d encoding:NSISOLatin1StringEncoding];
        }
        UMRegexMatch *m = [[UMRegexMatch alloc]init];
        m.start = (ssize_t)start;
        m.end = (ssize_t)end;
        m.matched = matched;
        [a addObject:m];
    }
    if(pmatch)
    {
        free(pmatch);
        pmatch=NULL;
    }
    return a;
}

@end


