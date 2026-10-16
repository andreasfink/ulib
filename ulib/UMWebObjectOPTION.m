//
//  UMWebObjectOPTION.m
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import "UMWebObjectOPTION.h"

@implementation UMWebObjectOPTION


- (UMWebObjectOPTION *)init
{
    self = [super init];
    if(self)
    {
        self.tag = @"option";
        _noWrap=YES;
    }
    return self;
}

- (UMWebObjectOPTION *)initWithValue:(NSString *)value text:(NSString *)text
{
    self = [self init];
    if(self)
    {
        _value = value;
        [self addText:text];
    }
    return self;
}

- (void)prepareAttributes
{
    if(_isDefault > 0)
    {
        [self setAttributeWithoutValue:@"selected"];
    }
    if(_value.length > 0)
    {
        [self setAttribute:@"value" value:_value];
    }
}

- (void)postprocessAttributes
{
    if(_attributes[@"selected"])
    {
        _isDefault = YES;
    }
    else
    {
        _isDefault = NO;
    }
    id v = _attributes[@"value"];
    if([v isKindOfClass:[NSString class]])
    {
        _value = (NSString *)v;
    }
}

@end
