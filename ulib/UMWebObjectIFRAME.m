//
//  UMWebObjectIFRAME.m
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import "UMWebObjectIFRAME.h"

@implementation UMWebObjectIFRAME


- (UMWebObjectIFRAME *)init
{
    self = [super init];
    if(self)
    {
        self.tag = @"iframe";
    }
    return self;
}

@end
