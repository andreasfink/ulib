//
//  UMDirtyDouble.m
//  ulib
//
//  Created by Andreas Fink on 04.03.2025.
//

#import "UMDirtyDouble.h"

#include <stdlib.h>
#ifdef	__APPLE__
#include <xlocale.h> /* for atof()*/
#endif
#include <stdlib.h>

@implementation UMDirtyDouble


- (UMDirtyDouble *)initWithDouble:(double)d
{
    self = [super init];
    if(self)
    {
        _currentValue = @(d);
        _previousValue = NULL;
        _isDirty = YES;
    }
    return self;
}

- (UMDirtyDouble *)initWithNumber:(NSNumber *)n
{
    return [self initWithDouble:n.doubleValue];
}

- (UMDirtyDouble *)initWithString:(NSString *)s
{
    double d = atof(s.UTF8String);
    return [self initWithDouble:d];
}

- (NSNumber *)number
{
    return _currentValue;
}

- (void)setNumber:(NSNumber *)n
{

    _previousValue = _currentValue;
    _currentValue = @(n.doubleValue);

    NSNumber *n1 = (NSNumber *)_previousValue;
    NSNumber *n2 = (NSNumber *)_currentValue;
    if(n1.doubleValue != n2.doubleValue)
    {
        _isDirty = YES;
    }
}


- (NSString *)stringValue
{
    return [NSString stringWithFormat:@"%@",_currentValue];
}

- (void)setStringValue:(NSString *)s
{
    double d = atof(s.UTF8String);
    [self setDoubleValue:d];
}

- (void)setDoubleValue:(double)newValue
{
    [self setNumber:@(newValue)];
}

- (double)doubleValue
{
    NSNumber *n = (NSNumber *)_currentValue;
    return n.doubleValue;
}


- (double)previousDoubleValue
{
    NSNumber *n = (NSNumber *)_previousValue;
    return n.doubleValue;

}

- (NSString *)previousStringValue
{
    return [NSString stringWithFormat:@"%@",_previousValue];
}

- (UMDirtyDouble *)copyWithZone:(NSZone *)zone
{
    return [[UMDirtyDouble allocWithZone:zone]initWithDouble:self.doubleValue];
}
@end
