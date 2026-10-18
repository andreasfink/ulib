//
//  UMWebObjectLINK.m
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import "UMWebObjectLINK.h"

@implementation UMWebObjectLINK


- (UMWebObjectLINK *)init
{
    self = [super init];
    if(self)
    {
        self.tag = @"link";
        _noWrap = YES;

    }
    return self;
}


@end
