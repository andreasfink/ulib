//
//  UMWebObjectTABLE.m
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import "UMWebObjectTABLE.h"

@implementation UMWebObjectTABLE

- (UMWebObjectTABLE *)init
{
    self = [super init];
    if(self)
    {
        self.tag = @"table";
    }
    return self;
}

@end
