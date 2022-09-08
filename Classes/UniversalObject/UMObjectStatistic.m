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
static int umobject_stat_index_from_ascii(const char *asciiName);

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
    global_object_stat = NULL;
}


+ (UMObjectStatistic *)sharedInstance
{
	return global_object_stat;
}

- (UMObjectStatistic *)init
{
	self = [super init];
	if(self)
	{
        /* we can not save this mutex in object stat as this would potentially create a recurise loop */
        for(int i=0;i<UMOBJECT_STATISTIC_SPREAD;i++)
        {
            _olock[i] = [[UMMutex alloc]initWithName:@"UMObjectStatistic-lock" saveInObjectStat:NO];
            _dict[i] = [[NSMutableDictionary alloc]init];
        }
	}
	return self;
}

extern void umobject_stat_verify_ascii_name(const char *asciiName);

static int umobject_stat_index_from_ascii(const char *asciiName)
{
    int i=0;
    int sum=0;
    while(asciiName[i]!=0)
    {
        sum += asciiName[i++];
    }
    return (sum % UMOBJECT_STATISTIC_SPREAD);
}

- (UMObjectStatisticEntry *)getEntryForAsciiName:(const char *)asciiName
{
	NSString *nsName = @(asciiName);
	NSAssert(nsName.length!=0,@"name length is 0. %s",asciiName);
	NSAssert(_dict,@"_dict is NULL");
	NSAssert(_olock,@"_olock is NULL");
    int index = umobject_stat_index_from_ascii(asciiName);
	UMObjectStatisticEntry *entry = NULL;
	[_olock[index] lock];
	entry = _dict[index][nsName];
	if(entry == NULL)
	{
		umobject_stat_verify_ascii_name(asciiName); /* just in case */
		entry = [[UMObjectStatisticEntry alloc]init];
		entry.name = asciiName;
		_dict[index][nsName] = entry;
	}
	[_olock[index] unlock];
	return entry;
}

- (NSArray<UMObjectStatisticEntry *> *)getObjectStatistic:(BOOL)sortByName
{
	NSMutableArray *arr = [[NSMutableArray alloc]init];
    for(int index=0;index<UMOBJECT_STATISTIC_SPREAD;index++)
    {
        [_olock[index] lock];
        NSArray *keys = [_dict[index] allKeys];
        for(NSString *key in keys)
        {
            UMObjectStatisticEntry *e = _dict[index][key];
            [arr addObject: [e copy] ];
        }
        [_olock[index] unlock];
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

+ (void)increaseAllocCounter:(const char *)asciiName
{
    UMObjectStatistic *os = [UMObjectStatistic sharedInstance];
    [os increaseAllocCounter:asciiName];
}

- (void)increaseAllocCounter:(const char *)asciiName
{
	VERIFY_ASCII_NAME(asciiName);
	UMObjectStatisticEntry *entry = [self getEntryForAsciiName:asciiName];
	[entry increaseAllocCounter];
}

+ (void)decreaseAllocCounter:(const char *)asciiName
{
    UMObjectStatistic *os = [UMObjectStatistic sharedInstance];
    [os decreaseAllocCounter:asciiName];
}

- (void)decreaseAllocCounter:(const char *)asciiName
{
	VERIFY_ASCII_NAME(asciiName);
	UMObjectStatisticEntry *entry = [self getEntryForAsciiName:asciiName];
	[entry decreaseAllocCounter];
}

+ (void)increaseDeallocCounter:(const char *)asciiName
{
    UMObjectStatistic *os = [UMObjectStatistic sharedInstance];
    [os increaseDeallocCounter:asciiName];
}

- (void)increaseDeallocCounter:(const char *)asciiName
{
	VERIFY_ASCII_NAME(asciiName);
	UMObjectStatisticEntry *entry = [self getEntryForAsciiName:asciiName];
	[entry increaseDeallocCounter];
}

+ (void)decreaseDeallocCounter:(const char *)asciiName
{
    UMObjectStatistic *os = [UMObjectStatistic sharedInstance];
    [os decreaseDeallocCounter:asciiName];
}

- (void)decreaseDeallocCounter:(const char *)asciiName
{
	VERIFY_ASCII_NAME(asciiName);
	UMObjectStatisticEntry *entry = [self getEntryForAsciiName:asciiName];
	[entry decreaseDeallocCounter];
}

@end
