//
//  UMDoubleWithHistory.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMDoubleWithHistory.h>

@implementation UMDoubleWithHistory

-(void)setDouble:(double)newValue
{
    _oldValue = _currentValue;
    _currentValue = @(newValue);
    if([((NSNumber *)_currentValue) doubleValue] != [((NSNumber *)_oldValue) doubleValue])
    {
        _isModified = YES;
    }
    else
    {
        _isModified=NO;
    }
}

- (double)double
{
    return [self currentDouble];
}

- (double)currentDouble
{
    return [((NSNumber *)_currentValue) doubleValue];
}

- (double)oldDouble
{
    return [((NSNumber *)_oldValue) doubleValue];

}

-(NSString *)nonNullString
{
    return [NSString stringWithFormat:@"%lf",[((NSNumber *)_currentValue) doubleValue]];
}

- (NSString *)oldNonNullString
{
    return [NSString stringWithFormat:@"%lf",[((NSNumber *)_oldValue) doubleValue]];
}


- (void) loadFromString:(NSString *)str
{
    self.currentValue = @(atof([str UTF8String]));
}


- (NSString *)description
{
    if(_isModified)
    {
        return [NSString stringWithFormat:@"Double '%8.4lf' (unmodified)",((NSNumber *)_currentValue).doubleValue];
    }
    else
    {
        return [NSString stringWithFormat:@"Double '%8.4lf' (changed from '%8.4lf')",((NSNumber *)_currentValue).doubleValue,((NSNumber *)_oldValue).doubleValue];
    }
}

+ (UMDoubleWithHistory *)doubleWithHistoryWithDouble:(double)d
{
    UMDoubleWithHistory *dh = [[UMDoubleWithHistory alloc]init];
    [dh setDouble:d];
    return dh;
}

@end
