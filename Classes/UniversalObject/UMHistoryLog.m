//
//  UMHistoryLog.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMHistoryLog.h"
#import "NSString+UniversalObject.h"
#import "UMHistoryLogEntry.h"
#import "UMAssert.h"
#import "NSDate+stringFunctions.h"

@implementation UMHistoryLog

- (UMHistoryLog *)init
{
    return [self initWithMaxLines:MAX_UMHISTORY_LOG];
}

- (UMHistoryLog *)initWithMaxLines:(int)maxlines
{
    self = [super init];
    if(self)
    {
        _entries = [[NSMutableArray alloc] init];
        _max = maxlines;
        _lock =[[UMMutex alloc]initWithName:@"history-lock"];
        //count = 0;
    }
    return self;
}

- (UMHistoryLog *)initWithString:(NSString *)s
{
    self = [self initWithMaxLines:MAX_UMHISTORY_LOG];
    if(self)
    {
        NSArray *lines = [s componentsSeparatedByCharactersInSet:[UMObject newlineCharacterSet]];
        for(NSString *line in lines)
        {
            [self addLogEntry:line];
        }
    }
    return self;
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
    [_lock lock];
    UMHistoryLogEntry *e = [[UMHistoryLogEntry alloc] initWithLog:log];
    [_entries addObject:e];
    [self trim];
    [_lock unlock];
}

- (NSArray *)getLogArrayWithDatesAndOrder:(BOOL)forward
{
    [_lock lock];
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
    [_lock unlock];
    return output;
}

- (NSArray *)getLogArrayWithOrder:(BOOL)forward
{
    [_lock lock];
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
        NSString *line = entry.log;
        if([line length]>0)
        {
            [output addObject:line];
        }
        position = position + direction;
    }
    [_lock unlock];
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
    return [self getLogForwardOrder];
}

@end
