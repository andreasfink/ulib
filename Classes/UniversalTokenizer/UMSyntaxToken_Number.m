//
//  UMSyntaxToken_Number.m
//  ulib
//
//  Created by Andreas Fink on 25.02.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import "UMSyntaxToken_Number.h"

@implementation UMSyntaxToken_Number

- (BOOL) matchesValue:(NSString *)value withPriority:(int)prio
{
    if(prio != UMSYNTAX_PRIORITY_NUMBER)
    {
        return NO;
    }
    int n = (int)[value integerValue];

    if((n < _min) || (n >_max))
    {
        return NO;
    }
    return YES;
}

@end
