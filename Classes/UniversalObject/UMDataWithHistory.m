//
//  UMDataWithHistory.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMDataWithHistory.h"
#import "NSData+UniversalObject.h"
#import "NSString+UniversalObject.h"

@implementation UMDataWithHistory


-(void)setData:(NSData *)newValue
{
    _oldValue = _currentValue;
    _currentValue = newValue;
    NSData *oldData = (NSData *)_oldValue;
    NSData *currentData = (NSData *)_currentValue;

    if([oldData isEqualToData:currentData])
    {
        _isModified = YES;
    }
    else
    {
        _isModified = NO;
    }
}

- (NSData *)data
{
    return [self currentData];
}

- (NSData *)currentData
{
    return (NSData *)_currentValue;
}

-(NSData *)oldData
{
    return (NSData *)_oldValue;
}

-(NSString *)nonNullString
{
    if(_currentValue==NULL)
    {
        return @"";
    }
    NSData *d = (NSData *)_currentValue;
    return [d hexString];
}

- (NSString *)oldNonNullString;
{
    if(_oldValue==NULL)
    {
        return @"";
    }
    NSData *d = (NSData *)_oldValue;
    return [d hexString];
}

- (void) loadFromString:(NSString *)str
{
    self.currentValue = [str unhexedData];
}


+ (UMDataWithHistory *)dataWithHistoryWithData:(NSData *)d
{
    UMDataWithHistory *dh = [[UMDataWithHistory alloc]init];
    dh.currentValue = d;
    return dh;

}
- (NSString *)description
{
    if(_isModified)
    {
        NSData *currentData = (NSData *)_currentValue;
        return [NSString stringWithFormat:@"Data '%@' (unmodified)",[currentData hexString]];
    }
    else
    {
        NSData *oldData = (NSData *)_oldValue;
        NSData *currentData = (NSData *)_currentValue;
        return [NSString stringWithFormat:@"Data '%@' (changed from '%@')",[currentData hexString],[oldData hexString]];
    }
}

@end
