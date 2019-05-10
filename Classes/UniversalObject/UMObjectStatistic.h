//
//  UMObjectStatistic.h
//  ulib
//
//  Created by Andreas Fink on 09.05.19.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UMObjectStatisticEntry.h"
@class UMMutex;
@interface UMObjectStatistic : NSObject
{
	NSMutableDictionary 		*_dict;
	UMMutex						*_lock;
	long long					_allocCount;
	long long					_dealloc;
}

+ (UMObjectStatistic *)sharedInstance;
+ (void)destroySharedInstance;

- (void)increaseAllocCounter:(const char *)asciiName;
- (void)decreaseAllocCounter:(const char *)asciiName;
- (void)increaseDeallocCounter:(const char *)asciiName;
- (void)decreaseDeallocCounter:(const char *)asciiName;
- (NSArray<UMObjectStatisticEntry *> *)getObjectStatistic:(BOOL)sortByName;

@end
