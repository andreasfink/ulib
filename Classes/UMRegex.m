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
#include <stdlib.h>
#include <string.h>

@implementation UMRegex

- (void) dealloc
{
    [self free];
}

- (void)free
{
    if(_preg)
    {
        regfree((regex_t *)_preg);
        free(_preg);
    }
    _preg=NULL;

    if(_str2)
    {
        free(_str2);
    }
    _str2=NULL;
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
        _rule = r;

        _preg = malloc(sizeof(regex_t));
        memset(_preg,0x00,sizeof(regex_t));
        const char *str = [_rule cStringUsingEncoding:NSASCIIStringEncoding];
        if(_str2)
        {
            free(_str2);
            _str2=NULL;
        }
        size_t bufsize = strlen(str)+1;
        _str2 = malloc(bufsize);
        memset(_str2,0x00,bufsize);
        strncpy (_str2,str,bufsize);
        int rc = regcomp((regex_t *)_preg,_str2,cflags);
        if(rc!=0)
        {
            char buffer[512];
            regerror(rc, (regex_t *)_preg, buffer, sizeof(buffer));
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
    if(_str2)
    {
        free(_str2);
        _str2=NULL;
    }
    size_t bufsize = strlen(str)+1;
    _str2 = malloc(bufsize);
    memset(_str2,0x00,bufsize);
    strncpy (_str2,str,bufsize);

    int rc = regexec((regex_t *)_preg, _str2,  nmatch, pmatch, eflags);
    if (rc != REG_NOMATCH && rc != 0)
    {
        char buffer[512];
        regerror(rc, (regex_t *)_preg, buffer, sizeof(buffer));
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


