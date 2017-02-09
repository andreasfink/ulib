//
//  UMLogConsole.h
//  ulib.framework
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"
#import "UMLogDestination.h"


@interface UMLogConsole : UMLogDestination
{
	
}

- (void) logAnEntry:(UMLogEntry *)logEntry;
- (void) unlockedLogAnEntry:(UMLogEntry *)logEntry;
- (void) logNow:(UMLogEntry *)logEntry;
- (NSString *)oneLineDescription;

@end
