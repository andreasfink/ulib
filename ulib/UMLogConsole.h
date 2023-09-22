//
//  UMLogConsole.h
//  ulib.framework
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMObject.h>
#import <ulib/UMLogDestination.h>


@interface UMLogConsole : UMLogDestination
{
	
}

- (void) logAnEntry:(UMLogEntry *)logEntry;
- (void) unlockedLogAnEntry:(UMLogEntry *)logEntry;
- (void) logNow:(UMLogEntry *)logEntry;
- (NSString *)oneLineDescription;

@end
