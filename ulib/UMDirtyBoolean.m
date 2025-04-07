//
//  UMDirtyBoolean.m
//  ulib
//
//  Created by Andreas Fink on 04.03.2025.
//

#import "UMDirtyBoolean.h"
#import <stdlib.h>

@implementation UMDirtyBoolean

- (UMDirtyBoolean *)initWithBoolean:(BOOL)b
{
    self = [super init];
    if(self)
    {
        _currentValue = b ? @(YES) : @(NO);
        _previousValue = NULL;
        _isDirty = YES;
    }
    return self;

}

- (UMDirtyBoolean *)initWithNumber:(NSNumber *)b
{
    return [self initWithBoolean:b.boolValue];
}

- (UMDirtyBoolean *)initWithString:(NSString *)s
{
    if(s!=NULL)
    {
        if([s caseInsensitiveCompare:@"true"]==NSOrderedSame)
        {
            return [self initWithBoolean:YES];
        }
        if([s caseInsensitiveCompare:@"yes"]==NSOrderedSame)
        {
            return [self initWithBoolean:YES];
        }
        if([s caseInsensitiveCompare:@"false"]==NSOrderedSame)
        {
            return [self initWithBoolean:NO];
        }
        if([s caseInsensitiveCompare:@"NO"]==NSOrderedSame)
        {
            return [self initWithBoolean:NO];
        }
        return [self initWithBoolean: atol(s.UTF8String) ? YES : NO];
    }
    return NULL;
}

- (NSNumber *)number
{
    return (NSNumber *)_currentValue;
}

- (NSNumber *)previousNumber
{
    return (NSNumber *)_previousValue;
}

- (void)setNumber:(NSNumber *)n
{
    _previousValue = _currentValue;
    _currentValue = @(n.boolValue);
    NSNumber *n1 = _previousValue;
    NSNumber *n2 = _currentValue;
    if(n1.boolValue != n2.boolValue)
    {
        _isDirty = YES;
    }
}

- (BOOL)booleanValue
{
    NSNumber *n = (NSNumber *)_currentValue;
    return n.boolValue;
}

- (BOOL)previousBooleanValue
{
    NSNumber *n = (NSNumber *)_previousValue;
    return n.boolValue;
}

- (void)setBooleanValue:(BOOL)newValue
{
    [self setNumber: newValue ? @(YES) : @(NO)];
}

- (NSString *)stringValue
{
    return self.booleanValue ? @"YES" : @"NO";
}

- (NSString *)previousStringValue
{
    return self.previousBooleanValue ? @"YES" : @"NO";
}

- (void)setStringValue:(NSString *)s
{
    if(s!=NULL)
    {
        BOOL b=NO;

        if([s caseInsensitiveCompare:@"true"]==NSOrderedSame)
        {
            b=YES;
        }
        else if([s caseInsensitiveCompare:@"YES"]==NSOrderedSame)
        {
            b=YES;
        }
        else if([s caseInsensitiveCompare:@"false"]==NSOrderedSame)
        {
            b=NO;
        }
        else if([s caseInsensitiveCompare:@"NO"]==NSOrderedSame)
        {
            b=NO;
        }
        else
        {
            b = atol(s.UTF8String) ? YES : NO;
        }
        [self setBooleanValue:b];
    }
}

- (UMDirtyBoolean *)copyWithZone:(NSZone *)zone
{
    return [[UMDirtyBoolean allocWithZone:zone]initWithBoolean:self.booleanValue];
}

@end
