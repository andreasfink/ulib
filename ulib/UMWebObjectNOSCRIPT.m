//
//  UMWebObjectNOSCRIPT.m
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import "UMWebObjectNOSCRIPT.h"

@implementation UMWebObjectNOSCRIPT


- (UMWebObjectNOSCRIPT *)init
{
    self = [super init];
    if(self)
    {
        self.tag = @"noscript";
    }
    return self;
}

@end
