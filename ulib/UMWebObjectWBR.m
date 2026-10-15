//
//  UMWebObjectWBR.m
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import "UMWebObjectWBR.h"

@implementation UMWebObjectWBR

- (UMWebObjectWBR *)init
{
    self = [super init];
    if(self)
    {
        self.tag = @"wbr";
    }
    return self;
}

@end
