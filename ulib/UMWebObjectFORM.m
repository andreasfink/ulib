//
//  UMWebObjectFORM.m
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import "UMWebObjectFORM.h"

@implementation UMWebObjectFORM

- (UMWebObjectFORM *)init
{
    self = [super init];
    if(self)
    {
        self.tag = @"form";
    }
    return self;
}

@end
