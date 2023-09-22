//
//  UMRegex.h
//  ulib
//
//  Created by Andreas Fink on 08.07.16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#include <regex.h>
#include <ctype.h>

#import <ulib/UMObject.h>

#import <ulib/UMRegexMatch.h>

@interface UMRegex : UMObject
{
    NSString *_rule;
    void *_preg;
    char *_str2;
}

@property(readwrite,strong) NSString *rule;

- (UMRegex *)initWithString:(NSString *)r flags:(int)cflags;
- (NSArray *)regexExec:(NSString *)string
              maxMatch:(int)max
                 flags:(int)eflags;

@end
