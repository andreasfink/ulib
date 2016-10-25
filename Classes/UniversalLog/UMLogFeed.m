//
//  UMLogFeed.m
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//


#import "UMLogFeed.h"
#import "UMUtil.h"

@implementation UMLogFeed

@synthesize handler;
@synthesize section;
@synthesize subsection;
@synthesize name;
@synthesize copyToConsole;


- (UMLogFeed *)initWithHandler:(UMLogHandler *)h
{
    return [self initWithHandler:h section:@""];
}

- (UMLogFeed *)initWithHandler:(UMLogHandler *)h section:(NSString *)s
{
    return [self initWithHandler:h section:s subsection:@""];
}

- (UMLogFeed *)initWithHandler:(UMLogHandler *)h section:(NSString *)s1 subsection:(NSString *)s2
{
    self = [super init];
	if(self)
    {
	    section = s1;
	    subsection = s2;
	    handler = h;
    }
	return self;
}


- (UMLogFeed *) copyWithZone:(NSZone *)zone
{
    UMLogFeed *n = [[UMLogFeed alloc]initWithHandler:handler section:section subsection:subsection];
    n.name = [NSString stringWithFormat:@"%@ (copy)",name];
    n.copyToConsole = copyToConsole;
    return n;
}

- (UMLogLevel)level
{
    return handler.level;
}

- (void) debug:		(int)err withText:(NSString *)txt
{
	UMLogEntry *e;
	
	e = [[UMLogEntry alloc] init];
	[e setLevel: UMLOG_DEBUG];
	[e setSection: section];
	[e setSubsection: subsection];
	[e setName: name];
	[e setErrorCode: err];
	[e setMessage: txt];
	[handler logAnEntry:e];
	if(copyToConsole)
    {
		NSLog(@"%@\n",e);
    }
}

- (void) info:		(int)err withText:(NSString *)txt
{
	UMLogEntry *e;
	
	e = [[UMLogEntry alloc] init];
	[e setLevel: UMLOG_INFO];
	[e setSection: section];
	[e setSubsection: subsection];
	[e setName: name];
	[e setErrorCode: err];
	[e setMessage: txt];
	[handler logAnEntry:e];
	if(copyToConsole)
    {
		NSLog(@"%@\n",e);
    }
}

- (void) warning:	(int)err withText:(NSString *)txt
{
	UMLogEntry *e;
	
	e = [[UMLogEntry alloc] init];
	[e setLevel: UMLOG_WARNING];
	[e setSection: section];
	[e setSubsection: subsection];
	[e setName: name];
	[e setErrorCode: err];
	[e setMessage: txt];
	[handler logAnEntry:e];
	if(copyToConsole)
    {
		NSLog(@"%@\n",e);
    }
	
}

- (void) minorError:(int)err withText:(NSString *)txt
{
	UMLogEntry *e;
	
	e = [[UMLogEntry alloc] init];
	[e setLevel: UMLOG_MINOR];
	[e setSection: section];
	[e setSubsection: subsection];
	[e setName: name];
	[e setErrorCode: err];
	[e setMessage: txt];
	[handler logAnEntry:e];
	if(copyToConsole)
    {
		NSLog(@"%@\n",e);
    }
	
}

- (void) majorError:(int)err withText:(NSString *)txt
{
	UMLogEntry *e;
	
	e = [[UMLogEntry alloc] init];
	[e setLevel: UMLOG_MAJOR];
	[e setSection: section];
	[e setSubsection: subsection];
	[e setName: name];
	[e setErrorCode: err];
	[e setMessage: txt];
	[handler logAnEntry:e];
	if(copyToConsole)
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
	[e setSection: section];
	[e setSubsection: subsection];
	[e setName: name];
	[e setErrorCode: err];
	[e setMessage: logtext];
    [handler logAnEntry:e];
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
	[e setSection:		section];
	[e setSubsection:	s];
	[e setName:		name];
	[e setErrorCode:	err];
	[e setMessage:		txt];
	[handler logAnEntry:e];
	if(copyToConsole)
    {
		NSLog(@"%@\n",e);
    }
	
}

- (void) info:		(int)err inSubsection:(NSString *)s withText:(NSString *)txt
{
	UMLogEntry *e;
	
	e = [[UMLogEntry alloc] init];
	[e setLevel:		UMLOG_INFO];
	[e setSection:		section];
	[e setSubsection:	s];
	[e setName:		name];
	[e setErrorCode:	err];
	[e setMessage:		txt];
	[handler logAnEntry:e];
	if(copyToConsole)
    {
		NSLog(@"%@\n",e);
    }
	
}

- (void) warning:	(int)err inSubsection:(NSString *)s withText:(NSString *)txt
{
	UMLogEntry *e;
	
	e = [[UMLogEntry alloc] init];
	[e setLevel:		UMLOG_WARNING];
	[e setSection:		section];
	[e setSubsection:	s];
	[e setName:		name];
	[e setErrorCode:	err];
	[e setMessage:		txt];
	[handler logAnEntry:e];
	if(copyToConsole)
    {
		NSLog(@"%@\n",e);
    }
}

- (void) minorError:(int)err inSubsection:(NSString *)s withText:(NSString *)txt
{
	UMLogEntry *e;
	
	e = [[UMLogEntry alloc] init];
	[e setLevel:		UMLOG_MINOR];
	[e setSection:		section];
	[e setSubsection:	s];
	[e setName:		name];
	[e setErrorCode:	err];
	[e setMessage:		txt];
	[handler logAnEntry:e];
}

- (void) majorError:(int)err inSubsection:(NSString *)s withText:(NSString *)txt
{
	UMLogEntry *e;
	
	e = [[UMLogEntry alloc] init];
	[e setLevel:		UMLOG_MAJOR];
	[e setSection:		section];
	[e setSubsection:	s];
	[e setName:		name];
	[e setErrorCode:	err];
	[e setMessage:		txt];
	[handler logAnEntry:e];
	if(copyToConsole)
    {
		NSLog(@"%@\n",e);
    }
}

- (void) panic:		(int)err inSubsection:(NSString *)s withText:(NSString *)txt
{
	UMLogEntry *e;
	
	e = [[UMLogEntry alloc] init];
	[e setLevel:		UMLOG_PANIC];
	[e setSection:		section];
	[e setSubsection:	s];
	[e setName:		name];
	[e setErrorCode:	err];
	[e setMessage:		txt];
	[handler logAnEntry:e];
	if(copyToConsole)
    {
		NSLog(@"%@\n",e);
    }
}

- (void) infoUnlocked:(int)err withText:(NSString *)txt
{
	UMLogEntry *e;
	
	e = [[UMLogEntry alloc] init];
	[e setLevel:		UMLOG_INFO];
	[e setSection:		section];
	[e setSubsection:	subsection];
	[e setName:		name];
	[e setErrorCode:	err];
	[e setMessage:		txt];
	[handler unlockedLogAnEntry:e];
	if(copyToConsole)
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

