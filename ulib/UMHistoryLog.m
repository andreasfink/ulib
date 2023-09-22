//
//  UMHistoryLog.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMHistoryLog.h>
#import <ulib/NSString+UniversalObject.h>
#import <ulib/UMHistoryLogEntry.h>
#import <ulib/UMAssert.h>
#import <ulib/NSDate+stringFunctions.h>

@implementation UMHistoryLog

- (UMHistoryLog *)init
{
    return [self initWithMaxLines:MAX_UMHISTORY_LOG string:NULL];
}


- (UMHistoryLog *)initWithMaxLines:(int)maxlines
{
    return [self initWithMaxLines:maxlines string:NULL];
}

- (UMHistoryLog *)initWithMaxLines:(int)maxlines string:(NSString *)s
{
    self = [super init];
    if(self)
    {
        _entries = [[NSMutableArray alloc] init];
        _max = maxlines;
        _historyLogLock = [[UMMutex alloc]initWithName:@"history-lock"];
        if(s)
        {
            NSArray *lines = [s componentsSeparatedByCharactersInSet:[UMObject newlineCharacterSet]];
            for(NSString *line in lines)
            {
                [self addLogEntry:line];
            }
        }
    }
    return self;
}

- (UMHistoryLog *)initWithString:(NSString *)s
{
    return  [self initWithMaxLines:MAX_UMHISTORY_LOG string:s];
}

- (void)addPrintableString:(NSString *)s
{
    NSString *ps = [s printable];
    [self addLogEntry:ps];
}

- (void)trim
{
    if(_max>0)
    {
		NSInteger cnt = [_entries count];
		if(cnt > _max)
		{
        	NSInteger itemsToRemove = cnt - _max;
            [_entries removeObjectsInRange:NSMakeRange(0,itemsToRemove)];
        }
    }
}


- (void)addLogEntry:(NSString *)log
{
    UMMUTEX_LOCK(_historyLogLock);
    UMHistoryLogEntry *e = [[UMHistoryLogEntry alloc] initWithLog:log];
    [_entries addObject:e];
    [self trim];
    UMMUTEX_UNLOCK(_historyLogLock);
}

- (NSArray *)getLogArrayWithDatesAndOrder:(BOOL)forward
{
    UMMUTEX_LOCK(_historyLogLock);
    NSMutableArray *output = [[NSMutableArray alloc]init];
    NSInteger count = [_entries count];
    NSInteger position;
    NSInteger direction;

    if(forward)
    {
        position = 0;
        direction = 1;
    }
    else
    {
        position = count - 1;
        direction = -1;

    }

    while(count--)
    {
        UMHistoryLogEntry *entry = _entries[position];
        NSString *line = [entry stringValue];
        if([line length]>0)
        {
            [output addObject:line];
        }
        position = position + direction;
    }
    UMMUTEX_UNLOCK(_historyLogLock);
    return output;
}

- (NSArray *)getLogArrayWithOrder:(BOOL)forward
{
    UMMUTEX_LOCK(_historyLogLock);
    NSMutableArray *output = [[NSMutableArray alloc]init];
    NSInteger count = [_entries count];
    NSInteger position;
    NSInteger direction;

    if(forward)
    {
        position = 0;
        direction = 1;
    }
    else
    {
        position = count - 1;
        direction = -1;

    }
    while(count--)
    {
        UMHistoryLogEntry *entry = _entries[position];
        NSString *line = [entry stringValueWithoutDate];
        if([line length]>0)
        {
            [output addObject:line];
        }
        position = position + direction;
    }
    UMMUTEX_UNLOCK(_historyLogLock);
    return output;
}

- (void)addObject:(id)entry
{
    if ([entry isKindOfClass:[NSString class]])
    {
        [self addLogEntry:entry];
    }
    else
    {
        [self addLogEntry:[entry stringValue]];
 
    }
}

- (NSString *)getLogBackwardOrder
{
    NSArray *a = [self getLogArrayWithOrder:NO];
    return [a componentsJoinedByString:@"\n"];
}

- (NSString *)getLogBackwardOrderWithDates
{
    NSArray *a = [self getLogArrayWithDatesAndOrder:NO];
    return [a componentsJoinedByString:@"\n"];
}

- (NSString *)getLogForwardOrder
{
    NSArray *a = [self getLogArrayWithOrder:YES];
    return [a componentsJoinedByString:@"\n"];
}

- (NSString *)getLogForwardOrderWithDates
{
    NSArray *a = [self getLogArrayWithDatesAndOrder:YES];
    return [a componentsJoinedByString:@"\n"];
}


- (NSString *)description
{
    return [self getLogForwardOrder];
}


- (NSString *)stringLines
{
    return [self getLogForwardOrderWithDates];
}

@end
