//
//  UMLogFeed.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//


#import "UMLogFeed.h"
#import "UMUtil.h"
extern NSString *UMBacktrace(void **stack_frames, size_t size);

@implementation UMLogFeed


- (UMLogFeed *)initWithHandler:(UMLogHandler *)h
{
    return [self initWithHandler:h section:@""];
}

- (UMLogFeed *)initWithHandler:(UMLogHandler *)h section:(NSString *)s
{
    return [self initWithHandler:h section:s subsection:@""];
}

- (UMLogFeed *)initWithHandler:(UMLogHandler *)h
					   section:(NSString *)s1
					subsection:(NSString *)s2
{
    self = [super init];
	if(self)
    {
	    _section = s1;
	    _subsection = s2;
	    _handler = h;
    }
	return self;
}


- (UMLogFeed *) copyWithZone:(NSZone *)zone
{
    UMLogFeed *n = [[UMLogFeed alloc]initWithHandler:_handler section:_section subsection:_subsection];
    n.name = [NSString stringWithFormat:@"%@ (copy)",_name];
    n.copyToConsole = _copyToConsole;
    return n;
}

- (UMLogLevel)level
{
    return self.handler.level;
}

- (void) debug:		(int)err withText:(NSString *)txt
{
	UMLogEntry *e;
	
	e = [[UMLogEntry alloc] init];
	[e setLevel: UMLOG_DEBUG];
	[e setSection: _section];
	[e setSubsection: _subsection];
	[e setName: _name];
	[e setErrorCode: err];
	[e setMessage: txt];
	[_handler logAnEntry:e];
	if(_copyToConsole)
    {
		NSLog(@"%@\n",e);
    }
}

- (void) info:		(int)err withText:(NSString *)txt
{
	UMLogEntry *e;
	
	e = [[UMLogEntry alloc] init];
	[e setLevel: UMLOG_INFO];
	[e setSection:_section];
	[e setSubsection:_subsection];
	[e setName:_name];
	[e setErrorCode: err];
	[e setMessage: txt];
	[_handler logAnEntry:e];
	if(_copyToConsole)
    {
		NSLog(@"%@\n",e);
    }
}

- (void) warning:	(int)err withText:(NSString *)txt
{
	UMLogEntry *e;
	
	e = [[UMLogEntry alloc] init];
	[e setLevel: UMLOG_WARNING];
	[e setSection:_section];
	[e setSubsection:_subsection];
	[e setName:_name];
	[e setErrorCode: err];
	[e setMessage: txt];
	[_handler logAnEntry:e];
	if(_copyToConsole)
    {
		NSLog(@"%@\n",e);
    }
	
}

- (void) minorError:(int)err withText:(NSString *)txt
{
	UMLogEntry *e;
	
	e = [[UMLogEntry alloc] init];
	[e setLevel: UMLOG_MINOR];
	[e setSection: _section];
	[e setSubsection: _subsection];
	[e setName: _name];
	[e setErrorCode: err];
	[e setMessage: txt];
	[_handler logAnEntry:e];
	if(_copyToConsole)
    {
		NSLog(@"%@\n",e);
    }
	
}

- (void) majorError:(int)err withText:(NSString *)txt
{
	UMLogEntry *e;
	
	e = [[UMLogEntry alloc] init];
	[e setLevel: UMLOG_MAJOR];
	[e setSection: _section];
	[e setSubsection: _subsection];
	[e setName: _name];
	[e setErrorCode: err];
	[e setMessage: txt];
	[_handler logAnEntry:e];
	if(_copyToConsole)
    {
		NSLog(@"%@\n",e);
    }
	
}

- (void) panic: (int)err withText:(NSString *)txt
{
	UMLogEntry *e;
    NSString *bt = UMBacktrace(NULL,0);
    NSString *logtext = [NSString stringWithFormat:@"%@\r\n%@",txt,bt];
	e = [[UMLogEntry alloc] init];
	[e setLevel: UMLOG_PANIC];
	[e setSection: _section];
	[e setSubsection: _subsection];
	[e setName: _name];
	[e setErrorCode: err];
	[e setMessage: logtext];
    [_handler logAnEntry:e];
    NSLog(@"%@\n",e);
  
}


- (void) debugText:(NSString *)txt
{
	[self debug:0 withText:txt];
}

- (void) infoText:(NSString *)txt
{
	[self info:0 withText:txt];
}

- (void) warningText:(NSString *)txt
{
	[self warning:0 withText:txt];
}

- (void) minorErrorText:(NSString *)txt
{
	[self minorError:0 withText:txt];
}

- (void) majorErrorText:(NSString *)txt
{
	[self majorError:0 withText:txt];
}

- (void) panicText:(NSString *)txt
{
	[self panic:0 withText:txt];
}

- (void) debug:		(int)err inSubsection:(NSString *)s withText:(NSString *)txt
{
	UMLogEntry *e;
	
	e = [[UMLogEntry alloc] init];
	[e setLevel:		UMLOG_DEBUG];
	[e setSection:		_section];
	[e setSubsection:	s];
	[e setName:		_name];
	[e setErrorCode:	err];
	[e setMessage:		txt];
	[_handler logAnEntry:e];
	if(_copyToConsole)
    {
		NSLog(@"%@\n",e);
    }
	
}

- (void) info:		(int)err inSubsection:(NSString *)s
	 withText:(NSString *)txt
{
	UMLogEntry *e;
	
	e = [[UMLogEntry alloc] init];
	[e setLevel:		UMLOG_INFO];
	[e setSection:		_section];
	[e setSubsection:	s];
	[e setName:		_name];
	[e setErrorCode:	err];
	[e setMessage:		txt];
	[_handler logAnEntry:e];
	if(_copyToConsole)
    {
		NSLog(@"%@\n",e);
    }
	
}

- (void) warning:	(int)err inSubsection:(NSString *)s withText:(NSString *)txt
{
	UMLogEntry *e;
	
	e = [[UMLogEntry alloc] init];
	[e setLevel:		UMLOG_WARNING];
	[e setSection:		_section];
	[e setSubsection:	s];
	[e setName:		_name];
	[e setErrorCode:	err];
	[e setMessage:		txt];
	[_handler logAnEntry:e];
	if(_copyToConsole)
    {
		NSLog(@"%@\n",e);
    }
}

- (void) minorError:(int)err inSubsection:(NSString *)s withText:(NSString *)txt
{
	UMLogEntry *e;
	
	e = [[UMLogEntry alloc] init];
	[e setLevel:		UMLOG_MINOR];
	[e setSection:		_section];
	[e setSubsection:	s];
	[e setName:		_name];
	[e setErrorCode:	err];
	[e setMessage:		txt];
	[_handler logAnEntry:e];
}

- (void) majorError:(int)err inSubsection:(NSString *)s withText:(NSString *)txt
{
	UMLogEntry *e;
	
	e = [[UMLogEntry alloc] init];
	[e setLevel:		UMLOG_MAJOR];
	[e setSection:		_section];
	[e setSubsection:	s];
	[e setName:		_name];
	[e setErrorCode:	err];
	[e setMessage:		txt];
	[_handler logAnEntry:e];
	if(_copyToConsole)
    {
		NSLog(@"%@\n",e);
    }
}

- (void) panic:		(int)err inSubsection:(NSString *)s withText:(NSString *)txt
{
	UMLogEntry *e;
	
	e = [[UMLogEntry alloc] init];
	[e setLevel:		UMLOG_PANIC];
	[e setSection:		_section];
	[e setSubsection:	s];
	[e setName:		_name];
	[e setErrorCode:	err];
	[e setMessage:		txt];
	[_handler logAnEntry:e];
	if(_copyToConsole)
    {
		NSLog(@"%@\n",e);
    }
}

- (void) infoUnlocked:(int)err withText:(NSString *)txt
{
	UMLogEntry *e;
	
	e = [[UMLogEntry alloc] init];
	[e setLevel:		UMLOG_INFO];
	[e setSection:		_section];
	[e setSubsection:	_subsection];
	[e setName:		_name];
	[e setErrorCode:	err];
	[e setMessage:		txt];
	[_handler unlockedLogAnEntry:e];
	if(_copyToConsole)
    {
		NSLog(@"%@\n",e);
    }
}


@end

void UMDebugLog(UMLogFeed *feed,const char *file,const unsigned long line, const char *func, const char *fn, id format, ...)
{
	if ([format isKindOfClass:[NSString class]])
	{
		va_list args;
		va_start(args, format);
		NSString *msg = [[NSString alloc] initWithFormat:format arguments:args];
		va_end(args);
		[feed debugText:[NSString stringWithFormat:@"%s:%ld %s(): %@\n", file,line,func, msg]];
//		[feed performSelectorOnMainThread:@selector(debugText) withObject:[NSString stringWithFormat:@"%s:%ld %s(): %@", file,line,func, msg] waitUntilDone:NO];
	}
	else
	{
		[feed debugText:[NSString stringWithFormat:@"%s:%ld %s(): %@\n", file,line,func, format]];
//		[feed performSelectorOnMainThread:@selector(debugText) withObject:[NSString stringWithFormat:@"%s:%ld %s(): %@", file,line,func, format] waitUntilDone:NO];
	}
}

