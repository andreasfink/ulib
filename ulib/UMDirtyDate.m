//
//  UMDirtyDate.m
//  ulib
//
//  Created by Andreas Fink on 04.03.2025.
//
<<<<<<< HEAD
#import <ulib/framework.h>
=======

>>>>>>> bd8ae622abb748fc043563e7e90d719fe523addd
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
<<<<<<< HEAD
    if(![d1 isEqualToDate:d2])
=======
    if(![d1 isEqualTo:d2])
>>>>>>> bd8ae622abb748fc043563e7e90d719fe523addd
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
