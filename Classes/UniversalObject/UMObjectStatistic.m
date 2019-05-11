//
//  UMObjectStatistic.m
//  ulib
//
//  Created by Andreas Fink on 09.05.19.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UMMutex.h"

#import "UMObjectStatistic.h"
#import "UMObjectStatisticEntry.h"

static UMObjectStatistic *global_object_stat = NULL;


@implementation UMObjectStatistic

+ (void)enable
{
    if(global_object_stat==NULL)
    {
        global_object_stat = [[UMObjectStatistic alloc]init];
    }
}

+ (void)disable
{
    global_object_stat =NULL;
}


+ (UMObjectStatistic *)sharedInstance
{
	return global_object_stat;
}

+ (void)destroySharedInstance
{
	global_object_stat = NULL;
}

- (UMObjectStatistic *)init
{
	self = [super init];
	if(self)
	{
        /* we can not save this mutex in object stat as this would potentially create a recurise loop */
        _lock = [[UMMutex alloc]intiWithName:@"UMObjectStatistic-lock" saveInObjectStat:NO];
		_dict = [[NSMutableDictionary alloc]init];
	}
	return self;
}

extern void umobject_stat_verify_ascii_name(const char *asciiName);

- (UMObjectStatisticEntry *)getEntryForAsciiName:(const char *)asciiName
{
	NSString *nsName = @(asciiName);
	NSAssert(nsName.length!=0,@"name length is 0. %s",asciiName);
	NSAssert(_dict,@"_dict is NULL");
	NSAssert(_lock,@"_lock is NULL");

	UMObjectStatisticEntry *entry = NULL;
	[_lock lock];
	entry = _dict[nsName];
	if(entry == NULL)
	{
		umobject_stat_verify_ascii_name(asciiName); /* just in case */
		entry = [[UMObjectStatisticEntry alloc]init];
		entry.name = asciiName;
		_dict[nsName] = entry;
	}
	[_lock unlock];
	return entry;
}

- (NSArray<UMObjectStatisticEntry *> *)getObjectStatistic:(BOOL)sortByName
{
	NSMutableArray *arr = [[NSMutableArray alloc]init];
	[_lock lock];

	NSArray *keys = [_dict allKeys];
	for(NSString *key in keys)
	{
		[arr addObject: [_dict[key] copy] ];
	}
	NSArray *arr2 = [arr sortedArrayUsingComparator: ^(UMObjectStatisticEntry *a, UMObjectStatisticEntry *b)
					 {
						 if(sortByName)
						 {
							 int i = strcmp(a.name, b.name);
							 if(i<0)
							 {
								 return NSOrderedDescending;
							 }
							 if(i==0)
							 {
								 return NSOrderedSame;
						     }
							 return NSOrderedAscending;
						 }
						 else
						 {
							 if(a.inUseCounter == b.inUseCounter)
							 {
								 return NSOrderedSame;
							 }
							 if(a.inUseCounter < b.inUseCounter)
							 {
								 return NSOrderedDescending;
							 }
							 return NSOrderedAscending;
						 }
					 }];
	[_lock unlock];
	return arr2;
}

extern NSString *UMBacktrace(void **stack_frames, size_t size);

#define 	VERIFY_ASCII_NAME(asciiName) \
{\
	if(asciiName==NULL) \
	{ \
		NSString *s = UMBacktrace(NULL,0); \
		fprintf(stderr,"asciiName==NULL\n%s",s.UTF8String); \
		fflush(stderr); \
		NSAssert(0,@"asciName is NULL");\
	} \
	if(*asciiName=='\0') \
	{ \
		NSString *s = UMBacktrace(NULL,0); \
		fprintf(stderr,"asciiName==''\n%s",s.UTF8String); \
		fflush(stderr); \
		NSAssert(0,@"asciName points to empty string");\
	} \
}

- (void)increaseAllocCounter:(const char *)asciiName
{
	VERIFY_ASCII_NAME(asciiName);
	[_lock lock];
	UMObjectStatisticEntry *entry = [self getEntryForAsciiName:asciiName];
	[entry increaseAllocCounter];
	[_lock unlock];
}

- (void)decreaseAllocCounter:(const char *)asciiName
{
	VERIFY_ASCII_NAME(asciiName);
	[_lock lock];
	UMObjectStatisticEntry *entry = [self getEntryForAsciiName:asciiName];
	[entry decreaseAllocCounter];
	[_lock unlock];

}

- (void)increaseDeallocCounter:(const char *)asciiName
{
	VERIFY_ASCII_NAME(asciiName);
	[_lock lock];
	UMObjectStatisticEntry *entry = [self getEntryForAsciiName:asciiName];
	[entry increaseDeallocCounter];
	[_lock unlock];
}

- (void)decreaseDeallocCounter:(const char *)asciiName
{
	VERIFY_ASCII_NAME(asciiName);
	[_lock lock];
	UMObjectStatisticEntry *entry = [self getEntryForAsciiName:asciiName];
	[entry decreaseDeallocCounter];
	[_lock unlock];
}

@end
