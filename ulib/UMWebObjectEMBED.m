//
//  UMWebObjectEMBED.m
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import "UMWebObjectEMBED.h"

@implementation UMWebObjectEMBED

- (UMWebObjectEMBED *)init
{
    self = [super init];
    if(self)
    {
        self.tag = @"embed";
    }
    return self;
}

@end
