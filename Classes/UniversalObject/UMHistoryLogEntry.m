//
//  UMHistoryLogEntry.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import "UMHistoryLogEntry.h"


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

- (UMHistoryLogEntry *)initWithLog:(NSString *)newlog
{
    self = [super init];
    if(self)
    {
        _date = [NSDate date];
        _log = newlog;
    }
    return self;
}


@end
