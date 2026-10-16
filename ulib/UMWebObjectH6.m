//
//  UMWebObjectH6.m
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import "UMWebObjectH6.h"

@implementation UMWebObjectH6


- (UMWebObjectH6 *)init
{
    self = [super init];
    if(self)
    {
        self.tag = @"h6";
        self.noWrap = YES;
    }
    return self;
}

@end
