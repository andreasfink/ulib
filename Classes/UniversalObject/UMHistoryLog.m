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
        entries = [[NSMutableArray alloc] init];
        max = maxlines;
        //count = 0;
    }
    return self;
}

- (UMHistoryLog *)initWithString:(NSString *)s
{
    self = [self initWithMaxLines:MAX_UMHISTORY_LOG];
    if(self)
    {
        NSArray *lines = [s componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
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
    if(max>0)
    {
        int itemsToRemove = (int)[entries count] - max;
        if(itemsToRemove > 0)
        {
            [entries removeObjectsInRange:NSMakeRange(0,itemsToRemove)];
        }
    }
}


- (void)addLogEntry:(NSString *)log
{
    @synchronized(self)
    {
        UMHistoryLogEntry *e = [[UMHistoryLogEntry alloc] initWithLog:log];
        [entries addObject:e];
        [self trim];
    }
}

- (NSArray *)getLogArrayWithOrder:(BOOL)forward
{
    @synchronized(self)
    {
        NSMutableArray *output = [[NSMutableArray alloc]init];
        NSInteger count = [entries count];
        NSInteger position;
        NSInteger direction;
        
        if(forward)
        {
            position = 0;
            direction = 1;
        }
        else
        {
            position = count -1;
            direction = -1;

        }
        
        while(count--)
        {
            UMHistoryLogEntry *entry = entries[position];
            NSString *line = entry.log;
            if([line length]>0)
            {
                [output addObject:line];
            }
            
            position = position + direction;
        }
        return output;
    }
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

- (NSString *)getLogForwardOrder
{
    NSArray *a = [self getLogArrayWithOrder:YES];
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
