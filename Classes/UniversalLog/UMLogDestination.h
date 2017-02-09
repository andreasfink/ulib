//
//  UMLogDestination.h
//  ulib.framework
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMLogEntry.h"

@interface UMLogDestination : UMObject
{
	UMLogLevel		level;
	NSLock			*_lock;
	NSMutableArray	*debugSections;
    NSMutableArray  *onlyLogSubsections;
}

@property (readwrite,assign) UMLogLevel		level;
@property (readwrite,strong) NSMutableArray	*debugSections;


- (void) logAnEntry:(UMLogEntry *)logEntry;
- (void) unlockedLogAnEntry:(UMLogEntry *)logEntry;
- (void)logNow:(UMLogEntry *)message;
- (UMLogDestination *) init;
- (NSString *)description;
- (void)lock;
- (void)unlock;
- (NSString *)oneLineDescription;

@end
