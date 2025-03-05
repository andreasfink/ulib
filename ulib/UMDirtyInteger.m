//
//  UMDirtyInteger.m
//  ulib
//
//  Created by Andreas Fink on 04.03.2025.
//

#import "UMDirtyInteger.h"
#include <stdlib.h> /* for atol() */

@implementation UMDirtyInteger

- (UMDirtyInteger *)initWithInteger:(NSInteger)i
{
    self = [super init];
    if(self)
    {
        _currentValue = @(i);
        _previousValue = NULL;
        _isDirty = YES;
    }
    return self;
}

- (UMDirtyInteger *)initWithNumber:(NSNumber *)n
{
    return [self initWithInteger:n.integerValue];
}


- (UMDirtyInteger *)initWithString:(NSString *)s
{
    NSInteger i = atol(s.UTF8String);
    return [self initWithInteger:i];
}

- (NSNumber *)number
{
    return _currentValue;
}

- (NSNumber *)previousNumber
{
    return _previousValue;
}

- (void)setNumber:(NSNumber *)n
{
    _previousValue = _currentValue;
    _currentValue = @(n.integerValue);
    NSNumber *n1 = _previousValue;
    NSNumber *n2 = _currentValue;
    if(n1.integerValue != n2.integerValue)
    {
        _isDirty = YES;
    }
}
- (void)setIntegerValue:(NSInteger)newValue
{
    [self setNumber:@(newValue)];
}

- (NSInteger)integerValue
{
    return ((NSNumber *)_currentValue).integerValue;
}

- (NSInteger)previousIntegerValue
{
    return ((NSNumber *)_previousValue).integerValue;
}

- (NSString *)stringValue
{
    if(_currentValue == NULL)
    {
        return @"";
    }

    return [NSString stringWithFormat:@"%@",(NSNumber *)_currentValue];
}

- (NSString *)previousStringValue
{
    if(_previousValue == NULL)
    {
        return @"";
    }
    return [NSString stringWithFormat:@"%@",(NSNumber *)_previousValue];
}

- (void)setStringValue:(NSString *)s
{

    if((s) && ([s isKindOfClass:[NSString class]])) /* its not a NSNull object */
    {
        NSInteger i = atol(s.UTF8String);
        [self setIntegerValue:i];
    }
    else
    {
        
    }
}

- (UMDirtyInteger *)copyWithZone:(NSZone *)zone
{
    return [[UMDirtyInteger allocWithZone:zone]initWithInteger:self.integerValue];
}

@end
