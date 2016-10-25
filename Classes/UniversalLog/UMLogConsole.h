//
//  UMLogConsole.h
//  ulib.framework
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
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
