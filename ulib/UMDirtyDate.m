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

- (NSDate *)dateValue
{
    return (NSDate *)_currentValue;
}

- (void)setDateValue:(NSDate *)d
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

- (NSDate *)previousDateValue
{
    return (NSDate *)_previousValue;
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
    [self setDateValue:d];
}


- (NSString *)previousStringValue;
{
    NSDate *d = _previousValue;
    return d.stringValue;
}


- (UMDirtyDate *)copyWithZone:(NSZone *)zone
{
    return [[UMDirtyDate allocWithZone:zone]initWithDate:self.dateValue];
}

@end
