//
//  UMWebObjectHTML.m
//  ulib
//
//  Created by Andreas Fink on 16.10.2026.
//

#import <ulib/UMWebObjectHTML.h>
#import <ulib/UMWebObjectBODY.h>
#import <ulib/UMWebObjectHEAD.h>

@implementation UMWebObjectHTML


- (UMWebObjectHTML *)init
{
    self = [super init];
    if(self)
    {
        self.tag = @"html";
    }
    return self;
}


- (void)addChild:(UMWebObject *)c
{
    [super addChild:c];
    
    if([c isKindOfClass:[UMWebObjectBODY class]])
    {
        _body = (UMWebObjectBODY *)c;
    }
    if([c isKindOfClass:[UMWebObjectHEAD class]])
    {
        _head = (UMWebObjectHEAD *)c;
    }
}

@end
