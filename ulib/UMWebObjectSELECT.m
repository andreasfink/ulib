//
//  UMWebObjectSELECT.m
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import <ulib/UMWebObjectSELECT.h>
#import <ulib/UMWebObjectOPTION.h>

@implementation UMWebObjectSELECT

- (UMWebObjectSELECT *)init
{
    self = [super init];
    if(self)
    {
        self.tag = @"select";
    }
    return self;
}

- (void)select:(NSString *)value
{
    for(id child in _children)
    {
        if([child isKindOfClass:[UMWebObjectOPTION class]])
        {
            UMWebObjectOPTION *option = (UMWebObjectOPTION *)child;
            if([option.value isEqualToString:value])
            {
                option.isDefault = YES;
            }
            else
            {
                option.isDefault = NO;
            }
        }
    }
}

- (void)addOptionWithValue:(NSString *)value text:(NSString *)text
{
    UMWebObjectOPTION *o = [[UMWebObjectOPTION alloc]initWithValue:value text:text];
    [self addChild:o];
}

- (NSString *)htmlString:(BOOL)humanReadable
                   ident:(int)ident
                   flags:(UMWebObjectFlags)flags
{
    int oldflags = flags;
    
    flags = flags & ~UMWebObjectFlag_PRE;
    NSString *s = [super htmlString:humanReadable
                              ident:0
                              flags:flags];
    flags = oldflags;
    return s;
}
@end
