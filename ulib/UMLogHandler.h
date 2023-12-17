//
//  UMLogHandler.h
//  ulib.framework
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMLogDestination.h>
#import <ulib/UMLogConsole.h>
#import <ulib/UMMutex.h>

@class UMLogConsole, UMLogHandler, UMLogDestination;

@interface UMLogHandler : UMObject
{
	NSMutableArray	*_logDestinations;
	UMLogConsole	*_console;
    UMMutex         *_logHandlerLock;
    UMMutex         *_logDestinationsLock;
}

@property	(readwrite,strong,atomic)		UMLogConsole	*console;

- (UMLogHandler *) init;
- (UMLogHandler *) initWithConsole;
- (UMLogHandler *)initWithConsoleLogLevel:(UMLogLevel)clevel;
- (void) addLogDestination:(UMLogDestination *)dst;
- (void) removeLogDestination:(UMLogDestination *)dst;
- (void) logAnEntry:(UMLogEntry *)logEntry;
- (void) unlockedLogAnEntry:(UMLogEntry *)logEntry;

- (void) log:(UMLogLevel) level
     section:(NSString *)section
  subsection:(NSString *)subsection
        name:(NSString *)name
        text:(NSString *)message
   errorCode:(int)err;

- (UMLogLevel)level;
@end
