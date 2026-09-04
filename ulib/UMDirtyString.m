//
//  UMDirtyString.m
//  ulib
//
//  Created by Andreas Fink on 04.03.2025.
//

#import "UMDirtyString.h"
#import <ulib/NSString+ulib.h>

@implementation UMDirtyString


- (UMDirtyString *)initWithString:(NSString *)s
{
    self = [super init];
    if(self)
    {
        _currentValue = s;
        _previousValue = NULL;
        _isDirty = YES;
        _sizeLimit = 0;
    }
    return self;
}

- (UMDirtyString *)initWithString:(NSString *)s limit:(int)limit
{
    self = [super init];
    if(self)
    {
        _currentValue = [s limitToLength:limit];
        _previousValue = NULL;
        _isDirty = YES;
        _sizeLimit = limit;
    }
    return self;
}


- (NSString *)stringValue
{
    return _currentValue;
}

- (void)setStringValue:(NSString *)s
{
    if(_sizeLimit)
    {
        s = [s substringToIndex:_sizeLimit];
    }
    _previousValue = _currentValue;
    _currentValue = s;
    if(![s isEqualToString:_previousValue])
    {
        _isDirty = YES;
    }
}

- (UMDirtyString *)copyWithZone:(NSZone *)zone
{
    return [[UMDirtyString allocWithZone:zone]initWithString:self.stringValue];
}

@end
