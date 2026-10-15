//
//  UMWebObjectH.m
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import "UMWebObjectH.h"


@implementation UMWebObjectH

- (UMWebObjectH *)initWithLevel:(int)level
{
    self = [super init];
    if(self)
    {
        self.tag = [NSString stringWithFormat:@"H%d",level];
        self.noWrap=YES;
    }
    return self;
}

@end

