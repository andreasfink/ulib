//
//  UMWebObjectQ.m
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import "UMWebObjectQ.h"

@implementation UMWebObjectQ

- (UMWebObjectQ *)init
{
    self = [super init];
    if(self)
    {
        self.tag = @"q";
    }
    return self;
}

@end
