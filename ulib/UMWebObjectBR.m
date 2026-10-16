//
//  UMWebObjectBR.m
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import "UMWebObjectBR.h"

@implementation UMWebObjectBR

- (UMWebObjectBR *)init
{
    self = [super init];
    if(self)
    {
        self.tag = @"br";
        _noWrap=YES;
        _noEndTag=YES;
    }
    return self;
}

- (NSString *)htmlString:(BOOL)humanReadable
                   ident:(int)ident
                   flags:(UMWebObjectFlags)flags
{
    NSMutableString *s = [[NSMutableString alloc]initWithString:@"<br>"];
    if((humanReadable) && ((flags & UMWebObjectFlag_PRE)==0))
    {
        [UMWebObject appendLineEndingToMutableString:s];
    }
    return s;
}
@end
