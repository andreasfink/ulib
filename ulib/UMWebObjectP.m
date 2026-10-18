//
//  UMWebObjectP.m
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import "UMWebObjectP.h"


@implementation UMWebObjectP

- (UMWebObjectP *)init
{
    self = [super init];
    if(self)
    {
        self.tag = @"p";
    }
    return self;
}

- (NSString *)htmlString:(BOOL)humanReadable
                   ident:(int)ident
                   flags:(UMWebObjectFlags)flags
{
    [self prepareAttributes];
    return [super htmlString:humanReadable ident:ident flags:flags];
}
@end

