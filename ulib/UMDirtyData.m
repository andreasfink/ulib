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
    if(![d1 isEqualTo:d2])
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

@end
