//
//  UMDirtyDate.m
//  ulib
//
//  Created by Andreas Fink on 04.03.2025.
//

#import "UMDirtyDate.h"
#import "NSDate+ulib.h"
#import "NSString+ulib.h"

@implementation UMDirtyDate

- (UMDirtyDate *)initWithDate:(NSDate *)d
{
    self = [super init];
    if(self)
    {
        _currentValue = d;
        _previousValue = NULL;
        _isDirty = YES;
    }
    return self;
}

- (UMDirtyDate *)initWithString:(NSString *)s
{
    return [self initWithDate:s.dateValue];
}

- (NSDate *)date
{
    return (NSDate *)_currentValue;
}

- (void)setDate:(NSDate *)d
{

    _previousValue = _currentValue;
    _currentValue = d;

    NSDate *d1 = (NSDate *)_previousValue;
    NSDate *d2 = (NSDate *)_currentValue;
    if(![d1 isEqualTo:d2])
    {
        _isDirty = YES;
    }
}

- (NSString *)stringValue
{
    NSDate *d = (NSDate *)_currentValue;
    NSString *s = [d stringValue];
    return s;
}

- (void)setStringValue:(NSString *)s
{
    NSDate *d = s.dateValue;
    [self setDate:d];
}


- (NSString *)previousStringValue;
{
    NSDate *d = _previousValue;
    return d.stringValue;
}

- (NSDate *)previousDateValue
{
    return (NSDate *)_previousValue;
}

- (UMDirtyDate *)copyWithZone:(NSZone *)zone
{
    return [[UMDirtyDate allocWithZone:zone]initWithDate:self.date];
}

@end
