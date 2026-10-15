//
//  UMWebObjectBODY.m
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import <ulib/UMWebObjectBODY.h>

@implementation UMWebObjectBODY

- (UMWebObjectBODY *)init
{
    self = [super init];
    if(self)
    {
        self.tag = @"BODY";
    }
    return self;
}

@end
