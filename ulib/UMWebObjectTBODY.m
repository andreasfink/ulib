//
//  UMWebObjectTBODY.m
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import "UMWebObjectTBODY.h"

@implementation UMWebObjectTBODY

- (UMWebObjectTBODY *)init
{
    self = [super init];
    if(self)
    {
        self.tag = @"tbody";
    }
    return self;
}

@end
