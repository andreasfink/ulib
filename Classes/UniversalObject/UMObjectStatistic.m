//
//  UMObjectStatistic.m
//  ulib
//
//  Created by Andreas Fink on 09.05.19.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObjectStatistic.h"
#import "UMObjectStatisticEntry.h"

static UMObjectStatistic *global_object_stat = NULL;


@implementation UMObjectStatistic

+ (UMObjectStatistic *)sharedInstance
{
	if(global_object_stat == NULL)
	{
		global_object_stat = [[UMObjectStatistic alloc]init];
	}
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
		_lock = [[NSLock alloc]init];
		_dict = [[NSMutableDictionary alloc]init];
	}
	return self;
}

extern void umobject_stat_verify_ascii_name(const char *asciiName);

- (UMObjectStatisticEntry *)getEntryForName:(const char *)asciiName
{
	NSString *nsName = @(asciiName);
	NSAssert(nsName.length!=0,@"name length is 0");
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

- (void)increaseAllocCounter:(const char *)asciiName
{
	[_lock lock];
	UMObjectStatisticEntry *entry = [self getEntryForName:asciiName];
	[entry increaseAllocCounter];
	[_lock unlock];
}

- (void)decreaseAllocCounter:(const char *)asciiName
{
	[_lock lock];
	UMObjectStatisticEntry *entry = [self getEntryForName:asciiName];
	[entry decreaseAllocCounter];
	[_lock unlock];

}

- (void)increaseDeallocCounter:(const char *)asciiName
{
	[_lock lock];
	UMObjectStatisticEntry *entry = [self getEntryForName:asciiName];
	[entry increaseDeallocCounter];
	[_lock unlock];
}

- (void)decreaseDeallocCounter:(const char *)asciiName
{
	[_lock lock];
	UMObjectStatisticEntry *entry = [self getEntryForName:asciiName];
	[entry decreaseDeallocCounter];
	[_lock unlock];
}

@end
