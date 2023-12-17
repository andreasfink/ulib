//
//  UMLogHandler.m
//  ulib.framework
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//


#import <ulib/UMLogHandler.h>
#import <ulib/UMLogConsole.h>
#import <ulib/UMLogDestination.h>
#import <ulib/UMLogFile.h>
#import <ulib/UMMutex.h>

@implementation UMLogHandler

- (void)genericInitialisation
{
    _logDestinationsLock = [[UMMutex alloc]initWithName:@"loghandler-destinations"];
    _logHandlerLock = [[UMMutex alloc]initWithName:@"loghandler-lock"];
    _logDestinations = [[NSMutableArray alloc] init];
}

- (UMLogHandler *) init
{
    self = [super init];
    if(self)
    {
        [self genericInitialisation];
    }
    return self;
}

- (UMLogHandler *)initWithConsole
{
    self = [super init];
    if(self)
    {
        [self genericInitialisation];
        _console = [[UMLogConsole alloc] init];
        [self addLogDestination:_console];
    }
	return self;
}

- (UMLogHandler *)initWithConsoleLogLevel:(UMLogLevel)clevel
{
    self = [super init];
    if(self)
    {
        [self genericInitialisation];

        _console = [[UMLogConsole alloc] init];
        _console.level = clevel;
        [self addLogDestination:_console];
    }
    return self;
}

- (void) addLogDestination:(UMLogDestination *)dst
{
    UMMUTEX_LOCK(_logDestinationsLock);
    [_logDestinations addObject: dst];
    UMMUTEX_UNLOCK(_logDestinationsLock);
}

- (void) removeLogDestination:(UMLogDestination *)dst
{
    NSUInteger i;

    UMMUTEX_LOCK(_logDestinationsLock);
    i = [_logDestinations indexOfObject: dst];
    if (i != NSNotFound)
    {
        [_logDestinations removeObjectAtIndex:i];
    }
    UMMUTEX_UNLOCK(_logDestinationsLock);
}

- (void) logAnEntry:(UMLogEntry *)logEntry
{
    UMMUTEX_LOCK(_logDestinationsLock);
    NSArray *dsts  = [_logDestinations copy];
    UMMUTEX_UNLOCK(_logDestinationsLock);

    UMLogDestination *dst = nil;
    for ( dst in dsts )
    {
        [dst logAnEntry:logEntry];
    }
}

- (void) unlockedLogAnEntry:(UMLogEntry *)logEntry
{
    UMLogDestination *dst;
    for ( dst in _logDestinations )
    {
        [dst unlockedLogAnEntry:logEntry];
    }
}

- (void) log:(UMLogLevel) level
     section:(NSString *)section
  subsection:(NSString *)subsection
        name:(NSString *)name
        text:(NSString *)message
   errorCode:(int)err
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
    UMMUTEX_LOCK(_logDestinationsLock);
    NSArray *dsts  = [_logDestinations copy];
    UMMUTEX_UNLOCK(_logDestinationsLock);

    NSMutableString *s = [[NSMutableString alloc]init];
    [s appendFormat:@"%@\n", [super description]];
    if(_console)
    {
         [s appendFormat:@" Logs to Console: %@\n",[_console oneLineDescription]];
    }

    UMLogDestination *logDestination;
    for(logDestination in dsts)
    {
        if(logDestination == _console)
        {
            continue;
        }
        [s appendFormat:@" Logs to: %@\n", [logDestination oneLineDescription]];
    }
    return s;
}

- (UMLogLevel)level
{
    UMMUTEX_LOCK(_logDestinationsLock);
    NSArray *dsts  = [_logDestinations copy];
    UMMUTEX_UNLOCK(_logDestinationsLock);

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
