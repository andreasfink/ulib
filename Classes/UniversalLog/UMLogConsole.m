//
//  UMLogConsole.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMLogConsole.h"


@implementation UMLogConsole

- (void) logAnEntry:(UMLogEntry *)logEntry
{
	UMLogLevel	entryLevel;
	
	entryLevel = [logEntry level];
    
	if((entryLevel == UMLOG_DEBUG) && ([debugSections count]  > 0))
	{
		if ([debugSections indexOfObject: [logEntry subsection]] != NSNotFound )
		{
			[self lock];
			[self logNow: logEntry];
			[self unlock];
		}
	}
    
	else if( entryLevel >= level )
	{
		[self lock];
		[self logNow: logEntry];
		[self unlock];
	}
}

- (void) unlockedLogAnEntry:(UMLogEntry *)logEntry
{
	UMLogLevel	entryLevel;
	
	entryLevel = [logEntry level];
    
	if((entryLevel == UMLOG_DEBUG) && ([debugSections count]  > 0))
	{
		if ([debugSections indexOfObject: [logEntry subsection]] != NSNotFound )
		{
			[self logNow: logEntry];
		}
	}
    
	else if( entryLevel >= level )
	{
		[self logNow: logEntry];
	}
}

- (void) logNow:(UMLogEntry *)logEntry
{
    @autoreleasepool
    {
        NSString	*s;
        s = [logEntry description];
        fprintf(stdout,"%s\r\n", [s UTF8String] );
        fflush(stdout);
    }
}


- (NSString *)oneLineDescription
{
    NSMutableString *s = [[NSMutableString alloc]init];
    [s appendFormat:@" output CONSOLE level %d %@",
     level,
     [UMLogEntry levelName:level]];
    
    if(debugSections)
    {
        BOOL first = YES;
        [s appendFormat:@" debugSection = { "];
        for(NSString *section in debugSections)
        {
            if(first)
            {
                [s appendFormat:@"{ %@",section];
                first = NO;
            }
            else
            {
                [s appendFormat:@", %@",section];
            }
        }
        [s appendFormat:@"} "];
    }
    
    
    if(onlyLogSubsections)
    {
        BOOL first = YES;
        [s appendFormat:@" onlyLogSubsections = { "];
        for(NSString *section in onlyLogSubsections)
        {
            if(first)
            {
                [s appendFormat:@"{ %@",section];
                first = NO;
            }
            else
            {
                [s appendFormat:@", %@",section];
            }
        }
        [s appendFormat:@"} "];
    }
    return s;
}

@end
