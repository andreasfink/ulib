//
//  UMWebObjectTITLE.h
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import <ulib/UMWebObject.h>


@interface UMWebObjectTITLE : UMWebObject

- (UMWebObjectTITLE *)init
{
    self = [super init];
    if(self)
    {
        self.tag = @"TITLE";
    }
    return self;
}

