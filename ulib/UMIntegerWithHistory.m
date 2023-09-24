//
//  UMIntegerWithHistory.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMIntegerWithHistory.h>

@implementation UMIntegerWithHistory

-(void)setInteger:(NSInteger)newValue
{

    _oldValue = _currentValue;
    _currentValue = [NSNumber numberWithInteger:newValue];
    NSNumber *currentNumber = (NSNumber *)_currentValue;
    NSNumber *oldNumber = (NSNumber *)_oldValue;
    if([currentNumber isEqualToNumber:oldNumber])
    {
        _isModified = YES;
    }
    else
    {
        _isModified=NO;
    }
}

- (NSInteger)integer
{
    return [self currentInteger];
}


- (NSInteger)currentInteger
{
    NSNumber *currentNumber = (NSNumber *)_currentValue;
    return [currentNumber integerValue];
}

- (NSInteger)oldInteger
{
    NSNumber *oldNumber = (NSNumber *)_oldValue;
    return [oldNumber integerValue];
}

-(NSString *)nonNullString
{
    return [NSString stringWithFormat:@"%ld",(long)(self.integer)];
}

- (NSString *)oldNonNullString;
{
    return [NSString stringWithFormat:@"%ld",(long)(self.integer)];
}

- (void) loadFromString:(NSString *)str
{
    _currentValue = [NSNumber numberWithInteger:(NSInteger)atol([str UTF8String])];
}


- (NSString *)description
{
    if(_isModified)
    {
        NSNumber *currentNumber = (NSNumber *)_currentValue;
        return [NSString stringWithFormat:@"Integer '%ld' (unmodified)",(long)currentNumber.integerValue];
    }
    else
    {
        NSNumber *currentNumber = (NSNumber *)_currentValue;
        NSNumber *oldNumber = (NSNumber *)_oldValue;
        return [NSString stringWithFormat:@"Integer '%ld' (changed from '%ld')",(long)currentNumber.integerValue,(long)oldNumber.integerValue];
    }
}

+ (UMIntegerWithHistory *)integerWithHistoryWithInteger:(int)i
{
    UMIntegerWithHistory *iwh = [[UMIntegerWithHistory alloc]init];
    [iwh setInteger:i];
    return iwh;
}



@end
