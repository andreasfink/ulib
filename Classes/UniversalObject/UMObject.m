//
//  UMObject.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#import "UMObject.h"
#import "UMHistoryLog.h"
#import "UMConfig.h"
#import "UMLogHandler.h"
#import "UMLogFeed.h"
#import "UMLogFile.h"
#import "NSString+UniversalObject.h"
#import "UMConstantStringsDict.h"
#import "UMObjectStatistic.h"
#import "UMMemoryHeader.h"

extern NSString *UMBacktrace(void **stack_frames, size_t size);




@interface UMObjectThreadStarter : NSObject
{
	SEL         _selector;
	id          _obj;
	const char *_file;
	long        _line;
	const char *_func;
}

@property(readwrite,assign,atomic) SEL         selector;
@property(readwrite,strong,atomic) id          obj;
@property(readwrite,assign,atomic) const char  *file;
@property(readwrite,assign,atomic) long        line;
@property(readwrite,assign,atomic) const char  *func;
@end

@implementation UMObjectThreadStarter
@end

/*!
 @class UMObject
 @brief The root object for ulib

 UMObject is a replacement for NSObject. It allows a log handler to be attached,
 getting instantiated from a config file and it has some debug variant UMObjectDebug
 which allow to trace where objects get allocated and deallocated and it
 has methods to run methods in background in another thread.
 */


@implementation UMObject

- (UMObject *) init
{
	UMConstantStringsDict *magicNames = [UMConstantStringsDict sharedInstance];
	self = [super init];
	if(self)
	{
		NSString *s = [[self class] description];
		_magic = [magicNames asciiStringFromNSString:s];
		_umobject_flags  |= UMOBJECT_FLAG_HAS_MAGIC;
		_objectStatisticsName = _magic;
        UMObjectStatistic *os = [UMObjectStatistic sharedInstance];
        if(os)
        {
            [os increaseAllocCounter:_objectStatisticsName];
            _umobject_flags  |= UMOBJECT_FLAG_COUNTED_IN_STAT;
        }
		_umobject_flags  |= UMOBJECT_FLAG_IS_INITIALIZED;
	}
	return self;
}

- (void)dealloc
{
	if(_umobject_flags & UMOBJECT_FLAG_COUNTED_IN_STAT)
	{
		[UMObjectStatistic increaseDeallocCounter:_objectStatisticsName];
    }
    _magic = "deallocated";
    _objectStatisticsName = _magic;
	_umobject_flags  |= UMOBJECT_FLAG_IS_RELEASED;
}

- (void) addLogFromConfigGroup:(NSDictionary *)grp
					 toHandler:(UMLogHandler *)handler
						logdir:(NSString *)logdir
{
	[self addLogFromConfigGroup:grp
					  toHandler:handler
					sectionName:grp[@"group"]
				 subSectionName:NULL
				   configOption:@"log-file"
						 logdir:logdir];
}

- (void) addLogFromConfigGroup:(NSDictionary *)grp
					 toHandler:(UMLogHandler *)handler
{
	[self addLogFromConfigGroup:grp toHandler:handler sectionName:[grp objectForKey:@"group"]];
}

- (void) addLogFromConfigGroup:(NSDictionary *)grp
					 toHandler:(UMLogHandler *)handler
				   sectionName:(NSString *)sec
{
	[self addLogFromConfigGroup:grp toHandler:handler
					sectionName:sec
				 subSectionName:NULL
				   configOption:@"log-file"];
}

- (void) addLogFromConfigGroup:(NSDictionary *)grp
					 toHandler:(UMLogHandler *)handler
				   sectionName:(NSString *)sec subSectionName:(NSString *)ss
{
	[self addLogFromConfigGroup:grp toHandler:handler sectionName:sec subSectionName:ss configOption:@"log-file"];
}

- (void) addLogFromConfigGroup:(NSDictionary *)grp
					 toHandler:(UMLogHandler *)handler
				   sectionName:(NSString *)sec
				subSectionName:(NSString *)ss
				  configOption:(NSString *)configOption
{
	[self addLogFromConfigGroup:grp toHandler:handler sectionName:sec subSectionName:ss configOption:configOption logdir:NULL];
}

- (void) addLogFromConfigGroup:(NSDictionary *)grp
					 toHandler:(UMLogHandler *)handler
				   sectionName:(NSString *)sec
				subSectionName:(NSString *)ss
				  configOption:(NSString *)configOption
						logdir:(NSString *)logdir
{
	NSString *logFileName;
	UMLogFile *dst;

	if (grp==NULL)
	{
		return;
	}
	logFileName = [grp objectForKey:configOption];
	if(logFileName==NULL)
	{
		return;
	}
	UMLogLevel logLevel = UMLOG_MAJOR;
	if(grp[@"log-level"])
	{
		logLevel = (UMLogLevel)[grp[@"log-level"]intValue];
	}
	if(logdir.length > 0)
	{
		logFileName = [logFileName fileNameRelativeToPath:logdir];
	}
	dst = [[UMLogFile alloc] initWithFileName:logFileName andSeparator:@"\n" ];
	if(dst==NULL)
	{
		return;
	}
	dst.level = logLevel;
	[handler addLogDestination:dst];
	UMLogFeed *feed = [[UMLogFeed alloc]initWithHandler:handler section:sec];
	self.logFeed = feed;
	//    section = [type retain];
	//    subsection = [ss retain];
	//    name = [NSString stringwithFormat:section:subsection];
}

- (NSString *)objectStatisticsName
{
	if(_objectStatisticsName)
	{
		return @(_objectStatisticsName);
	}
	return @(_magic);
}


- (void)setObjectStatisticsName:(NSString *)newName
{
	const char *oldName = _objectStatisticsName;

	UMConstantStringsDict *magicNames 	= [UMConstantStringsDict sharedInstance];
	_objectStatisticsName 				= [magicNames asciiStringFromNSString:newName];
	[UMObjectStatistic decreaseAllocCounter:oldName];
	[UMObjectStatistic increaseAllocCounter:_objectStatisticsName];
}


+ (NSCharacterSet *)whitespaceAndNewlineCharacterSet /* this differs from NSCharacterSet version by having LINE SEPARATOR' (U+2028)
													  in it as well (UTF8 E280AD) */
{
	static NSCharacterSet *_charset=NULL;

	if(_charset==NULL)
	{
		NSMutableCharacterSet *c  = [[NSCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy];
		[c addCharactersInRange:NSMakeRange((unsigned int) 0x0000 ,1)]; /*  NULL */
		[c addCharactersInRange:NSMakeRange((unsigned int) 0x0009 ,1)]; /*  CHARACTER TABULATION */
		[c addCharactersInRange:NSMakeRange((unsigned int) 0x000A ,1)]; /*  LINE FEED (LF) */
		[c addCharactersInRange:NSMakeRange((unsigned int) 0x000B ,1)]; /*  LINE TABULATION */
		[c addCharactersInRange:NSMakeRange((unsigned int) 0x000C ,1)]; /*  FORM FEED (FF) */
		[c addCharactersInRange:NSMakeRange((unsigned int) 0x000D ,1)]; /*  CARRIAGE RETURN (CR) */
		[c addCharactersInRange:NSMakeRange((unsigned int) 0x0020 ,1)]; /*  SPACE */
		[c addCharactersInRange:NSMakeRange((unsigned int) 0x0085 ,1)]; /*  NEXT LINE (NEL)  */
		[c addCharactersInRange:NSMakeRange((unsigned int) 0x00A0 ,1)]; /*  NO-BREAK SPACE */
		[c addCharactersInRange:NSMakeRange((unsigned int) 0x1680 ,1)]; /*  OGHAM SPACE MARK */
		[c addCharactersInRange:NSMakeRange((unsigned int) 0x180E ,1)]; /*  MONGOLIAN VOWEL SEPARATOR */
		[c addCharactersInRange:NSMakeRange((unsigned int) 0x2000 ,1)]; /*  EN QUAD  */
		[c addCharactersInRange:NSMakeRange((unsigned int) 0x2001 ,1)]; /*  EM QUAD  */
		[c addCharactersInRange:NSMakeRange((unsigned int) 0x2002 ,1)]; /*  EN SPACE */
		[c addCharactersInRange:NSMakeRange((unsigned int) 0x2003 ,1)]; /*  EM SPACE */
		[c addCharactersInRange:NSMakeRange((unsigned int) 0x2004 ,1)]; /*  THREE-PER-EM SPACE */
		[c addCharactersInRange:NSMakeRange((unsigned int) 0x2005 ,1)]; /*  FOUR-PER-EM SPACE */
		[c addCharactersInRange:NSMakeRange((unsigned int) 0x2006 ,1)]; /*  SIX-PER-EM SPACE */
		[c addCharactersInRange:NSMakeRange((unsigned int) 0x2007 ,1)]; /*  FIGURE SPACE */
		[c addCharactersInRange:NSMakeRange((unsigned int) 0x2008 ,1)]; /*  PUNCTUATION SPACE */
		[c addCharactersInRange:NSMakeRange((unsigned int) 0x2009 ,1)]; /*  THIN SPACE */
		[c addCharactersInRange:NSMakeRange((unsigned int) 0x200A ,1)]; /*  HAIR SPACE */
		[c addCharactersInRange:NSMakeRange((unsigned int) 0x2028 ,1)]; /*  LINE SEPARATOR */
		[c addCharactersInRange:NSMakeRange((unsigned int) 0x2029 ,1)]; /*  PARAGRAPH SEPARATOR */
		[c addCharactersInRange:NSMakeRange((unsigned int) 0x202F ,1)]; /*  NARROW NO-BREAK SPACE */
		[c addCharactersInRange:NSMakeRange((unsigned int) 0x205F ,1)]; /*  MEDIUM MATHEMATICAL SPACE */
		[c addCharactersInRange:NSMakeRange((unsigned int) 0x3000 ,1)]; /*  IDEOGRAPHIC SPACE */
		_charset = [((NSCharacterSet *)c) copy];
	}
	return _charset;
}

+ (NSCharacterSet *)newlineCharacterSet /* this differs from NSCharacterSet version by having LINE SEPARATOR' (U+2028)
										 in it as well (UTF8 E280AD) */
{
	static NSCharacterSet *_charset=NULL;

	if(_charset==NULL)
	{
		NSMutableCharacterSet *c  = [[NSCharacterSet newlineCharacterSet] mutableCopy];
		[c addCharactersInRange:NSMakeRange((unsigned int) 0x000C ,1)]; /*  FORM FEED (FF) */
		[c addCharactersInRange:NSMakeRange((unsigned int) 0x000D ,1)]; /*  CARRIAGE RETURN (CR) */
		[c addCharactersInRange:NSMakeRange((unsigned int) 0x0085 ,1)]; /*  NEXT LINE (NEL)  */
		[c addCharactersInRange:NSMakeRange((unsigned int) 0x2028 ,1)]; /*  LINE SEPARATOR */
		[c addCharactersInRange:NSMakeRange((unsigned int) 0x2029 ,1)]; /*  PARAGRAPH SEPARATOR */
		_charset = [((NSCharacterSet *)c) copy];
	}
	return _charset;
}


- (void)threadStarter:(UMObjectThreadStarter *)ts
{
	SEL sel = ts.selector;
	id obj = ts;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	[self performSelector:sel withObject:obj];
#pragma clang diagnostic pop
}

- (void)runSelectorInBackground:(SEL)aSelector
					 withObject:(id)anArgument
{
	UMObjectThreadStarter *ts = [[UMObjectThreadStarter alloc]init];
	ts.selector = aSelector;
	ts.obj      = anArgument;
	[NSThread detachNewThreadSelector:@selector(threadStarter:)
							 toTarget:self
						   withObject:ts];
}

- (void)runSelectorInBackground:(SEL)aSelector
					 withObject:(id)anArgument
						   file:(const char *)fil
						   line:(long)lin
					   function:(const char *)fun
{
	UMObjectThreadStarter *ts = [[UMObjectThreadStarter alloc]init];
	ts.selector = aSelector;
	ts.obj      = anArgument;
	ts.file     = fil;
	ts.line     = lin;
	ts.func     = fun;

	[NSThread detachNewThreadSelector:@selector(threadStarter:)
							 toTarget:self
						   withObject:ts];
}

- (void)runSelectorInBackground:(SEL)aSelector
{
	UMObjectThreadStarter *ts = [[UMObjectThreadStarter alloc]init];
	ts.selector = aSelector;
	ts.obj      = nil;

	[NSThread detachNewThreadSelector:@selector(threadStarter:)
							 toTarget:self
						   withObject:ts];
}

- (NSString *) descriptionWithPrefix:(NSString *)prefix
{
	return [[self description]prefixLines:prefix];
}

- (UMObject *)copyWithZone:(NSZone *)zone;
{
	UMObject *r = [[UMObject allocWithZone:zone]init];

	r->_magic = _magic;
	[r setObjectStatisticsName:@(_objectStatisticsName)];
	r->_umobject_flags = _umobject_flags;
	r->_umobject_flags |= UMOBJECT_FLAG_IS_COPIED;
	r.logFeed = _logFeed;
	return r;
}

int umobject_enable_object_stat(void)
{
	[UMObjectStatistic enable];
	return 1;
}

void umobject_disable_object_stat(void)
{
	[UMObjectStatistic disable];
}

NSArray *umobject_object_stat(BOOL sortByName)
{
    UMObjectStatistic *objectStat = [UMObjectStatistic sharedInstance];
	return [objectStat getObjectStatistic:sortByName];
}

BOOL umobject_object_stat_is_enabled(void)
{
    UMObjectStatistic *objectStat = [UMObjectStatistic sharedInstance];
	return ((objectStat==NULL) ? NO : YES );
}

+ (void) umobject_stat_verify_ascii_name:(const char *)asciiName
{
	NSAssert(asciiName!=NULL,@"ascii name is NULL");
	int len=0;
	char c =asciiName[len++];
	while((c!='\0') && (len > 64))
	{
		NSAssert(isprint(c),@"ascii name has unprintable character 0x%02x",c);
		c = asciiName[len++];
	}
	NSAssert(len < 64,@"ascii name is longer than 63 characters",c);
}

+ (const char *)umobject_get_constant_name_pointer:(const char *)file line:(long)line func:(const char *)func
{
	NSString *shortFileName = [@(file) lastPathComponent];
	NSString *name = [[NSString alloc]initWithFormat:@"%@:%ld %s()",shortFileName,line,func];
	UMConstantStringsDict *magicNames = [UMConstantStringsDict sharedInstance];
	return  [magicNames asciiStringFromNSString:name];
}

@end


const char *umobject_get_constant_name_pointer(const char *file, const long line, const char *func)
{
	const char *c = [UMObject umobject_get_constant_name_pointer:file line:line func:func];
	return c;
}

void umobject_stat_verify_ascii_name(const char *asciiName)
{
	[UMObject umobject_stat_verify_ascii_name:asciiName];
}

void umobject_stat_external_increase_name(const char *cname)
{
    UMObjectStatistic *objectStat = [UMObjectStatistic sharedInstance];

	[objectStat increaseAllocCounter:cname];
}

void umobject_stat_external_decrease_name(const char *cname)
{
    UMObjectStatistic *objectStat = [UMObjectStatistic sharedInstance];
	[objectStat increaseDeallocCounter:cname];
}

