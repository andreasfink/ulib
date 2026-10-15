//
//  UMWebObjectSELECT.m
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import "UMWebObjectSELECT.h"

@implementation UMWebObjectSELECT

- (UMWebObjectSELECT *)init
{
    self = [super init];
    if(self)
    {
        self.tag = @"select";
    }
    return self;
}

@end
