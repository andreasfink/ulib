//
//  UMWebObjectFIELDSET.m
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import "UMWebObjectFIELDSET.h"

@implementation UMWebObjectFIELDSET

- (UMWebObjectFIELDSET *)init
{
    self = [super init];
    if(self)
    {
        self.tag = @"fieldset";
    }
    return self;
}
@end
