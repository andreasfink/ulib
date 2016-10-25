//
//  UMHistoryLogEntry.m
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
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
        
    }
    return self;
}

- (UMHistoryLogEntry *)initWithLog:(NSString *)newlog
{
    self = [super init];
    if(self)
    {
        log = newlog;
    }
    return self;
}


@end
