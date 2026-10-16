//
//  UMWebObjectINPUT.m
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import "UMWebObjectINPUT.h"

@implementation UMWebObjectINPUT


- (UMWebObjectINPUT *)init
{
    self = [super init];
    if(self)
    {
        self.tag = @"input";
        _noWrap=YES;
        _noEndTag=YES;
    }
    return self;
}

- (UMWebObjectINPUT *)initTypeTextWithName:(NSString *)name
{
    self = [self init];
    if(self)
    {
        [self setAttribute:@"type" value:@"text"];
        [self setAttribute:@"name" value:name];
    }
    return self;
}

@end
