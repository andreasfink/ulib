//
//  UMWebObjectPRE.m
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import "UMWebObjectPRE.h"

@implementation UMWebObjectPRE

- (UMWebObjectPRE *)init
{
    self = [super init];
    if(self)
    {
        self.tag = @"pre";
    }
    return self;
}

- (NSString *)htmlString:(BOOL)humanReadable
                   ident:(int)ident
                   flags:(UMWebObjectFlags)flags
{
    flags = flags | UMWebObjectFlag_PRE;
    NSString *s = [super htmlString:humanReadable
                              ident:ident
                              flags:flags];
    flags = flags & ~UMWebObjectFlag_PRE;
    return s;
}


@end
