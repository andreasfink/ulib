//
//  UMSyntaxToken_Digits.m
//  ulib
//
//  Created by Andreas Fink on 28.03.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMSyntaxToken_Digits.h>

@implementation UMSyntaxToken_Digits


- (BOOL) matchesValue:(NSString *)value withPriority:(int)prio
{
    if(prio == UMSYNTAX_PRIORITY_NAME)
    {
        return YES;
    }
    return NO;
}

- (UMSyntaxToken_Digits *) initWithHelp:(NSString *)h
{
    self = [super initWithHelp:h];
    if(self)
    {
        _string = @"DIGITS";
    }
    return self;
}
@end
