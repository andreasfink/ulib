//
//  UMDirtyString.m
//  ulib
//
//  Created by Andreas Fink on 04.03.2025.
//

#import "UMDirtyString.h"

@implementation UMDirtyString


- (UMDirtyString *)initWithString:(NSString *)s
{
    self = [super init];
    if(self)
    {
        _currentValue = s;
        _previousValue = NULL;
        _isDirty = YES;
    }
    return self;
}


- (NSString *)stringValue
{
    return _currentValue;
}

- (void)setStringValue:(NSString *)s
{
    _previousValue = _currentValue;
    _currentValue = s;
    if(![s isEqualToString:_previousValue])
    {
        _isDirty = YES;
    }
}

@end
