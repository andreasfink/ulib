//
//  UMLogEntry.h
//  ulib.framework
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>

#import <ulib/UMLogLevel.h>
#import <ulib/UMObject.h>

@interface UMLogEntry : UMObject
{
	NSDate		*_timeStamp;
	UMLogLevel	_level;
	NSString	*_section;
	NSString	*_subsection;
	NSString	*_name;
	NSString	*_message;
	int			_errorCode;
}

@property	(readwrite,strong)	NSDate		*timeStamp;
@property	(readwrite,assign)	UMLogLevel	level;
@property	(readwrite,strong)	NSString	*section;
@property	(readwrite,strong)	NSString	*subsection;
@property	(readwrite,strong)	NSString	*name;
@property	(readwrite,strong)	NSString	*message;
@property	(readwrite,assign)	int			errorCode;

- (UMLogEntry *)init;
+ (NSString *)levelName:(UMLogLevel)l;
- (NSString *)description;

@end
