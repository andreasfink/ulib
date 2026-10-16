//
//  UMWebObjectH3.m
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import "UMWebObjectH3.h"

@implementation UMWebObjectH3

- (UMWebObjectH3 *)init
{
    self = [super init];
    if(self)
    {
        self.tag = @"h3";
        self.noWrap = YES;
    }
    return self;
}

@end
