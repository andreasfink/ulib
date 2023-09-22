//
//  UMSyntaxToken_Name.m
//  ulib
//
//  Created by Andreas Fink on 25.02.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import <ulib/UMSyntaxToken_Name.h>

@implementation UMSyntaxToken_Name


- (BOOL) matchesValue:(NSString *)value withPriority:(int)prio
{
    if(prio == UMSYNTAX_PRIORITY_NAME)
    {
        return YES;
    }
    return NO;
}

- (UMSyntaxToken_Name *) initWithHelp:(NSString *)h
{
    self = [super initWithHelp:h];
    if(self)
    {
        _string = @"NAME";
    }
    return self;
}

@end
