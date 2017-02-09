//
//  UMLogFeed.h
//  ulib.framework
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMLogHandler.h"

@interface UMLogFeed : NSObject /* can not be UMObject as UMObject uses logfeed */
{
	UMLogHandler *handler;
	NSString	*section;
	NSString	*subsection;
	NSString	*name;
	int			copyToConsole;
}

@property (readwrite,strong,atomic) UMLogHandler *handler;
@property (readwrite,strong,atomic) NSString	*section;
@property (readwrite,strong,atomic) NSString	*subsection;
@property (readwrite,strong,atomic) NSString	*name;
@property (readwrite,assign,atomic) int		copyToConsole;


- (UMLogFeed *) copyWithZone:(NSZone *)zone;

- (UMLogLevel)level;


- (UMLogFeed *)initWithHandler:(UMLogHandler *)h;
- (UMLogFeed *)initWithHandler:(UMLogHandler *)h section:(NSString *)s;
- (UMLogFeed *)initWithHandler:(UMLogHandler *)h section:(NSString *)s1 subsection:(NSString *)s2;

- (void) debug:		(int)err withText:(NSString *)txt;
- (void) info:		(int)err withText:(NSString *)txt;
- (void) warning:	(int)err withText:(NSString *)txt;
- (void) minorError:(int)err withText:(NSString *)txt;
- (void) majorError:(int)err withText:(NSString *)txt;
- (void) panic:		(int)err withText:(NSString *)txt;

- (void) debug:		(int)err inSubsection:(NSString *)s withText:(NSString *)txt;
- (void) info:		(int)err inSubsection:(NSString *)s withText:(NSString *)txt;
- (void) warning:	(int)err inSubsection:(NSString *)s withText:(NSString *)txt;
- (void) minorError:(int)err inSubsection:(NSString *)s withText:(NSString *)txt;
- (void) majorError:(int)err inSubsection:(NSString *)s withText:(NSString *)txt;
- (void) panic:		(int)err inSubsection:(NSString *)s withText:(NSString *)txt;

- (void) debugText:(NSString *)txt;
- (void) infoText:(NSString *)txt;
- (void) warningText:(NSString *)txt;
- (void) minorErrorText:(NSString *)txt;
- (void) majorErrorText:(NSString *)txt;
- (void) panicText:(NSString *)txt;

- (void) infoUnlocked:(int)err withText:(NSString *)txt;

@end

void UMDebugLog(UMLogFeed *feed,const char *file,const unsigned long line, const char *func, const char *fn, id format, ...);
#define UMDebug(logfeed,x...) UMDebugLog(logfeed,__FILE__,__LINE__,__func__,__PRETTY_FUNCTION__, x)
