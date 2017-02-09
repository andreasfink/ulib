//
//  UMLogHandler.h
//  ulib.framework
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMLogDestination.h"
#import "UMLogConsole.h"

@class UMLogConsole, UMLogHandler, UMLogDestination;

@interface UMLogHandler : UMObject
{
	NSMutableArray	*logDestinations;
	UMLogConsole	*console;
	NSLock			*lock;
}

@property	(readwrite,strong)		NSMutableArray	*logDestinations;
@property	(readwrite,strong)		UMLogConsole	*console;
@property	(readwrite,strong)		NSLock			*lock;

- (UMLogHandler *) init;
- (UMLogHandler *) initWithConsole;
- (void) addLogDestination:(UMLogDestination *)dst;
- (void) removeLogDestination:(UMLogDestination *)dst;
- (void) logAnEntry:(UMLogEntry *)logEntry;
- (void) unlockedLogAnEntry:(UMLogEntry *)logEntry;

- (void) log:(UMLogLevel) level section:(NSString *)section subsection:(NSString *)subsection name:(NSString *)name text:(NSString *)message errorCode:(int)err;

- (UMLogLevel)level;
@end
