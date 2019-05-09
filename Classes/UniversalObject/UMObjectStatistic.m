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

- (UMObjectStatisticEntry *)getEntryForName:(const char *)asciiName
{
	UMObjectStatisticEntry *entry;
	[_lock lock];
	entry = _dict[@(asciiName)];
	if(entry == NULL)
	{
		entry = [[UMObjectStatisticEntry alloc]init];
		entry.name = asciiName;
		_dict[@(asciiName)] = entry;
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
	UMObjectStatisticEntry *entry = [self getEntryForName:asciiName];
	[entry increaseAllocCounter];
}

- (void)decreaseAllocCounter:(const char *)asciiName
{
	UMObjectStatisticEntry *entry = [self getEntryForName:asciiName];
	[entry decreaseAllocCounter];

}

- (void)increaseDeallocCounter:(const char *)asciiName
{
	UMObjectStatisticEntry *entry = [self getEntryForName:asciiName];
	[entry increaseDeallocCounter];

}

- (void)decreaseDeallocCounter:(const char *)asciiName
{
	UMObjectStatisticEntry *entry = [self getEntryForName:asciiName];
	[entry decreaseDeallocCounter];
}

@end
