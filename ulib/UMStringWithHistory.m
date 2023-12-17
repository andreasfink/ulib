//
//  UMStringWithHistory.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMStringWithHistory.h>

@implementation UMStringWithHistory

-(void)setString:(NSString *)newString
{
    _oldValue = _currentValue;
    _currentValue = newString;
    NSString *_oldString = (NSString *)_oldValue;
    NSString *_currentString = (NSString *)_oldValue;
    if(![_currentString isEqualToString:_oldString])
    {
        _isModified = YES;
    }
    else
    {
        _isModified = NO;
    }
}

- (NSString *)string
{
    return [self currentString];
}

- (NSString *)currentString
{
    return (NSString *)_currentValue;
}

- (NSString *)oldString
{
    return (NSString *)_oldValue;
}

- (NSString *)nonNullString
{
    if(_currentValue==NULL)
    {
        return @"";
    }
    return (NSString *)_currentValue;
}

- (NSString *)oldNonNullString
{
    if(_oldValue==NULL)
    {
        return @"";
    }
    return (NSString *)_oldValue;
}


- (void) loadFromString:(NSString *)str
{
    _currentValue = str;
}

- (NSString *)description
{
    if(_isModified)
    {
        return [NSString stringWithFormat:@"String '%@' (unmodified)",(NSString *)_currentValue];
    }
    else
    {
        return [NSString stringWithFormat:@"String '%@' (changed from '%@')",(NSString *)_currentValue,(NSString *)_oldValue];
    }
}


+ (UMStringWithHistory *)stringWithHistoryWithString:(NSString *)s;
{
    UMStringWithHistory *sh = [[UMStringWithHistory alloc]init];
    [sh loadFromString:s];
    return sh;

}

@end
