//
//  UMLogHandler.m
//  ulib.framework
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//


#import "UMLogHandler.h"
#import "UMLogConsole.h"
#import "UMLogDestination.h"
#import "UMLogFile.h"


@implementation UMLogHandler

@synthesize	logDestinations;
@synthesize	console;
@synthesize	lock;

- (UMLogHandler *) init
{
    self = [super init];
    if(self)
    {
        logDestinations = [[NSMutableArray alloc] init];
        lock = [[NSLock alloc]init];
        _logDestinationsLock = [[UMMutex alloc]initWithName:@"loghandler-destinations"];
    }	return self;
}

- (UMLogHandler *)initWithConsole
{
    self = [super init];
    if(self)
    {
        logDestinations = [[NSMutableArray alloc] init];
        lock = [[NSLock alloc]init];
        console = [[UMLogConsole alloc] init];
        _logDestinationsLock = [[UMMutex alloc]initWithName:@"loghandler-destinations"];
        [self addLogDestination:console];
    }
	return self;
}

- (UMLogHandler *)initWithConsoleLogLevel:(UMLogLevel)clevel
{
    self = [super init];
    if(self)
    {
        logDestinations = [[NSMutableArray alloc] init];
        lock = [[NSLock alloc]init];
        console = [[UMLogConsole alloc] init];
        console.level = clevel;
        [self addLogDestination:console];
    }
    return self;
}

- (void) addLogDestination:(UMLogDestination *)dst
{
    [_logDestinationsLock lock];
    [logDestinations addObject: dst];
    [_logDestinationsLock unlock];
}

- (void) removeLogDestination:(UMLogDestination *)dst
{
    NSUInteger i;

    [_logDestinationsLock lock];
    i = [logDestinations indexOfObject: dst];
    if (i != NSNotFound)
    {
        [logDestinations removeObjectAtIndex:i];
    }
    [_logDestinationsLock unlock];
}

- (void) logAnEntry:(UMLogEntry *)logEntry
{
    [_logDestinationsLock lock];
    NSArray *dsts  = [logDestinations copy];
    [_logDestinationsLock unlock];

    UMLogDestination *dst = nil;
    for ( dst in dsts )
    {
        [dst logAnEntry:logEntry];
    }
}

- (void) unlockedLogAnEntry:(UMLogEntry *)logEntry
{
    UMLogDestination *dst;
    for ( dst in logDestinations )
    {
        [dst unlockedLogAnEntry:logEntry];
    }
}

- (void) log:(UMLogLevel) level section:(NSString *)section subsection:(NSString *)subsection name:(NSString *)name text:(NSString *)message errorCode:(int)err
{
	UMLogEntry *e;
	
	e = [[UMLogEntry alloc] init];
	[e setLevel: level];
	[e setSection: section];
	[e setSubsection: subsection];
	[e setName: name];
    [e setMessage: message];
	[e setErrorCode: err];
	[self logAnEntry:e];
}

- (NSString *)description
{
    [_logDestinationsLock lock];
    NSArray *dsts  = [logDestinations copy];
    [_logDestinationsLock unlock];

    NSMutableString *s = [[NSMutableString alloc]init];
    [s appendFormat:@"%@\n", [super description]];
    if(console)
    {
         [s appendFormat:@" Logs to Console: %@\n",[console oneLineDescription]];
    }

    UMLogDestination *logDestination;
    for(logDestination in dsts)
    {
        if(logDestination == console)
        {
            continue;
        }
        [s appendFormat:@" Logs to: %@\n", [logDestination oneLineDescription]];
    }
    return s;
}

- (UMLogLevel)level
{
    [_logDestinationsLock lock];
    NSArray *dsts  = [logDestinations copy];
    [_logDestinationsLock unlock];

    UMLogLevel minLevel = UMLOG_PANIC;
    UMLogDestination *dst;
        
    for (dst in dsts)
    {
        if(dst.level < minLevel)
        {
            minLevel = dst.level;
        }
    }
    return minLevel;
}

@end
