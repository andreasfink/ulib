//
//  UMWebObjectSECTION.m
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import "UMWebObjectSECTION.h"

@implementation UMWebObjectSECTION

- (UMWebObjectSECTION *)init
{
    self = [super init];
    if(self)
    {
        self.tag = @"section";
    }
    return self;
}

@end
