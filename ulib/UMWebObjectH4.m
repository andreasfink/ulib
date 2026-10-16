//
//  UMWebObjectH4.m
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import "UMWebObjectH4.h"

@implementation UMWebObjectH4

- (UMWebObjectH4 *)init
{
    self = [super init];
    if(self)
    {
        self.tag = @"h4";
        self.noWrap = YES;
    }
    return self;
}

@end
