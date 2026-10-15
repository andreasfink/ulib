//
//  UMWebObjectCOLGROUP.m
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import "UMWebObjectCOLGROUP.h"

@implementation UMWebObjectCOLGROUP

- (UMWebObjectCOLGROUP *)init
{
    self = [super init];
    if(self)
    {
        self.tag = @"colgroup";
    }
    return self;
}
@end
