//
//  UMLogDestination.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMLogDestination.h"
#import "UMLogFile.h"
#import "UMMutex.h"

@implementation UMLogDestination

@synthesize level;
@synthesize debugSections;

- (void)lock
{
    UMMUTEX_LOCK(_lock);
}

- (void)unlock
{
    UMMUTEX_LOCK(_lock);
}

- (UMLogDestination *) init
{
    self=[super init];
    if(self)
    {
        level = UMLOG_DEBUG;
        _lock =[[UMMutex alloc]initWithName:@"UMLogDestination-lock"];
        debugSections =  [[NSMutableArray alloc] init];
	}
    return self;
}

- (NSString *)oneLineDescription
{
    NSMutableString *s = [[NSMutableString alloc]init];
    [s appendFormat:@" level %d %@\n",
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

- (NSString *)description
{   
    NSMutableString *desc = [NSMutableString stringWithString:@"Debug destination dump starts\n"];
    [desc appendFormat:@"log level is %d\n", level];
    [desc appendFormat:@"debug sections are %@\n", debugSections];
    [desc appendString:@"Debug destination dump ends\n"];
    return desc;
}

- (void) logAnEntry:(UMLogEntry *)logEntry
{
	UMLogLevel	entryLevel;
	
	entryLevel = [logEntry level];

	if((entryLevel == UMLOG_DEBUG) && ([debugSections count]  > 0))
	{
		if ([debugSections indexOfObject: [logEntry subsection]] != NSNotFound)
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
		if ([debugSections indexOfObject: [logEntry subsection]] != NSNotFound)
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
	NSLog(@"%@",logEntry );
}

@end
