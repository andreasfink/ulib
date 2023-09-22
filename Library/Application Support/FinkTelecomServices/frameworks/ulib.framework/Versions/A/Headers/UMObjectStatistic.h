//
//  UMObjectStatistic.h
//  ulib
//
//  Created by Andreas Fink on 09.05.19.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ulib/UMObjectStatisticEntry.h>

#define     UMOBJECT_STATISTIC_SPREAD   64

@class UMMutex;
@interface UMObjectStatistic : NSObject
{
	NSMutableDictionary 		*_dict[UMOBJECT_STATISTIC_SPREAD];
	UMMutex						*_olock[UMOBJECT_STATISTIC_SPREAD];
	long long					_allocCount;
	long long					_dealloc;
}
 
+ (void)enable;
+ (void)disable;
+ (UMObjectStatistic *)sharedInstance;


+ (void)increaseAllocCounter:(const char *)asciiName;
+ (void)decreaseAllocCounter:(const char *)asciiName;
+ (void)increaseDeallocCounter:(const char *)asciiName;
+ (void)decreaseDeallocCounter:(const char *)asciiName;

- (void)increaseAllocCounter:(const char *)asciiName;
- (void)decreaseAllocCounter:(const char *)asciiName;
- (void)increaseDeallocCounter:(const char *)asciiName;
- (void)decreaseDeallocCounter:(const char *)asciiName;
- (NSArray<UMObjectStatisticEntry *> *)getObjectStatistic:(BOOL)sortByName;

@end
