//
//  UMLogEntry.m
//  ulib.framework
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//


#import "UMLogEntry.h"


@implementation UMLogEntry

@synthesize		timeStamp;
@synthesize		level;
@synthesize		section;
@synthesize		subsection;
@synthesize		name;
@synthesize		message;
@synthesize		errorCode;



- (UMLogEntry *)init
{
    self = [super init];
    if(self)
    {
	    timeStamp = [[NSDate alloc] init];
    }
	return self;
}

+ (NSString *)levelName:(UMLogLevel)l
{
	switch(l)
	{
		case	UMLOG_DEBUG:
			return @"DEBUG";
		case	UMLOG_INFO:
			return @"INFO";
		case	UMLOG_WARNING:
			return @"WARNING";
		case	UMLOG_MINOR:
			return @"MINOR";
		case	UMLOG_MAJOR:
			return @"MAJOR";
		case	UMLOG_PANIC:
			return @"PANIC";
	}
	return @"UNKNOWN_LEVEL";
}

- (NSString *)description
{
	const char *s;
	
	if(errorCode)
	{
		s = strerror(errorCode);

		/* dateime level section subsection objectname errorcode errorstring message */
		return [NSString stringWithFormat:@"%@\t%@\t%@\t%@\t%@\t%s (%d) %@",
				timeStamp,
				[UMLogEntry levelName:level],
				section,
				subsection,
				name,
				s ? s : "",errorCode,
				message];
	}
	/* dateime level section subsection objectname errorcode errorstring message */
	return [NSString stringWithFormat:@"%@\t%@\t%@\t%@\t%@\t%@",
			timeStamp,
			[UMLogEntry levelName:level],
			section,
			subsection,
			name,
			message];
}

@end
