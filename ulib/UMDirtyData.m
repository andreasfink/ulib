//
//  UMDirtyData.m
//  ulib
//
//  Created by Andreas Fink on 04.03.2025.
//

#import "UMDirtyData.h"
#import "NSString+ulib.h"
#import "NSData+ulib.h"

@implementation UMDirtyData


- (UMDirtyData *)initWithData:(NSData *)d
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

- (UMDirtyData *)initWithString:(NSString *)s
{
    return [self initWithData:s.unhexedData];
}

- (NSData *)data
{
    return (NSData *)_currentValue;
}

- (void)setData:(NSData *)d
{

    _previousValue = _currentValue;
    _currentValue = d;

    NSData *d1 = (NSData *)_previousValue;
    NSData *d2 = (NSData *)_currentValue;
<<<<<<< HEAD
    if(![d1 isEqualToData:d2])
=======
    if(![d1 isEqualTo:d2])
>>>>>>> bd8ae622abb748fc043563e7e90d719fe523addd
    {
        _isDirty = YES;
    }
}

- (NSString *)stringValue
{
    NSData *d = (NSData *)_currentValue;
    NSString *s = d.stringValue;
    return s;
}

- (void)setStringValue:(NSString *)s
{
    NSData *d = [s unhexedData];
    [self setData:d];
}

- (NSData *)previousData
{
    return (NSData *)_previousValue;
}

- (NSString *)previousStringValue
{
    NSData *d = (NSData *)_previousValue;
    NSString *s = d.stringValue;
    return s;
}

- (UMDirtyData *)copyWithZone:(NSZone *)zone
{
    return [[UMDirtyData allocWithZone:zone]initWithData:self.data];
}

@end
