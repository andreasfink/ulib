//
//  UMLogEntry.m
//  ulib.framework
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMDateTimeStuff.h>
#import <ulib/UMLogEntry.h>

@implementation UMLogEntry


- (UMLogEntry *)init
{
    self = [super init];
    if(self)
    {
        _timeStamp = [NSDate date];
    }
	return self;
}

+ (NSString *)levelName:(UMLogLevel)l
{
    switch(l)
    {
        case    UMLOG_UNDEFINED:
            return @"UNDEFINED";
        case    UMLOG_DEBUG:
            return @"DEBUG";
        case    UMLOG_INFO:
            return @"INFO";
        case    UMLOG_WARNING:
            return @"WARNING";
        case    UMLOG_MINOR:
            return @"MINOR";
        case    UMLOG_MAJOR:
            return @"MAJOR";
        case    UMLOG_PANIC:
            return @"PANIC";
    }
    return @"UNKNOWN_LEVEL";
}


- (NSString *)description
{
	const char *s;
	
	if(_errorCode)
	{
		s = strerror(_errorCode);

		/* dateime level section subsection objectname errorcode errorstring message */
		return [NSString stringWithFormat:@"%@\t%@\t%@\t%@\t%@\t%s (%d) %@",
				_timeStamp,
				[UMLogEntry levelName:_level],
				_section,
				_subsection,
				_name,
				s ? s : "",_errorCode,
				_message];
	}
	/* dateime level section subsection objectname errorcode errorstring message */
	return [NSString stringWithFormat:@"%@\t%@\t%@\t%@\t%@\t%@",
			_timeStamp,
			[UMLogEntry levelName:_level],
			_section,
			_subsection,
			_name,
			_message];
}

@end
