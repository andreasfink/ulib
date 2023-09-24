//
//  UMSyntaxToken_Const.m
//  ulib
//
//  Created by Andreas Fink on 25.02.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import <ulib/UMSyntaxToken_Const.h>
#import <ulib/NSString+ulib.h>

@implementation UMSyntaxToken_Const


- (BOOL) matchesValue:(NSString *)value withPriority:(int)prio
{

    if(prio != UMSYNTAX_PRIORITY_CONSTANT)
    {
        return NO;
    }

    if(_caseSensitive == YES)
    {
        if([_string isEqualToString:value])
        {
           return YES;
        }
    }
    else
    {
        if([_string isEqualToStringCaseInsensitive:value])
        {
            return YES;
        }
    }
    return NO;
}

- (BOOL) startsWithValue:(NSString *)value withPriority:(int)prio fullValue:(NSString **)fullValue
{
    if(value.length<1)
    {
        return NO;
    }
    NSInteger n = value.length;
    NSInteger m = _string.length;
    if(m<n)
    {
        n=m;
    }
    NSString *s = [_string substringToIndex:n];
    NSString *v = [value substringToIndex:n];

    if(prio != UMSYNTAX_PRIORITY_CONSTANT)
    {
        return NO;
    }

    if(_caseSensitive == YES)
    {
        if([s isEqualToString:v])
        {
            if(fullValue)
            {
                *fullValue = _string;
            }
            return YES;
        }
    }
    else
    {
        if([s isEqualToStringCaseInsensitive:v])
        {
            if(fullValue)
            {
                *fullValue = _string;
            }
            return YES;
        }
    }
    return NO;
}

@end
