//
//  UMWebObjectSVG.m
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import "UMWebObjectSVG.h"

@implementation UMWebObjectSVG

- (UMWebObjectSVG *)init
{
    self = [super init];
    if(self)
    {
        self.tag = @"svg";
    }
    return self;
}

@end
