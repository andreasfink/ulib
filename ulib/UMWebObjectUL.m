//
//  UMWebObjectUL.m
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import "UMWebObjectUL.h"

@implementation UMWebObjectUL

- (UMWebObjectUL *)init
{
    self = [super init];
    if(self)
    {
        self.tag = @"ul";
    }
    return self;
}

@end
