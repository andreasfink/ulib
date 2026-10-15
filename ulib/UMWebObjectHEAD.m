//
//  UMWebObjectHEAD.m
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import <ulib/UMWebObjectHEAD.h>

@implementation UMWebObjectHEAD

- (UMWebObjectHEAD *)init
{
    self = [super init];
    if(self)
    {
        self.tag = @"HEAD";
    }
    return self;
}

@end
