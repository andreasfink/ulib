//
//  UMRegex.h
//  ulib
//
//  Created by Andreas Fink on 08.07.16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#include <regex.h>
#include <ctype.h>

#import "UMObject.h"

#import "UMRegexMatch.h"

@interface UMRegex : UMObject
{
    NSString *rule;
    void *preg;
}

@property(readwrite,strong) NSString *rule;


- (UMRegex *)initWithString:(NSString *)r flags:(int)cflags;

/* returns an array of UMRegexMatch objects: */
- (NSArray *)regexExec:(NSString *)string
             maxMatch:(int)max
                flags:(int)eflags;

@end
