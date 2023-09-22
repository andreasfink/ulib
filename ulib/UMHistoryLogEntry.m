//
//  UMHistoryLogEntry.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import <ulib/UMHistoryLogEntry.h>
#import <ulib/NSDate+stringFunctions.h>


@implementation UMHistoryLogEntry

@synthesize log;

- (UMHistoryLogEntry *)init
{
    self = [super init];
    if(self)
    {
        _date = [NSDate date];
    }
    return self;
}

- (UMHistoryLogEntry *)initWithLog:(NSString *)log
{
    self = [super init];
    if(self)
    {
        _date = [NSDate date];
        _log = log;
    }
    return self;
}

- (NSString *)stringValue
{
    NSString *ds = [_date stringValue];
    return [NSString stringWithFormat:@"%@ %@",ds,_log];
}

- (NSString *)stringValueWithoutDate
{
    return [NSString stringWithFormat:@"%@",_log];
}

@end
