//
//  UMObjectStatisticEntry.h
//  ulib
//
//  Created by Andreas Fink on 09.05.19.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UMObjectStatisticEntry : NSObject
{
	NSLock *_lock;
	long long _allocCounter;
	long long _deallocCounter;
	long long _inUseCounter;
	const char *_name;
}

@property(readwrite,assign) const char *name;

- (void)increaseAllocCounter;
- (void)decreaseAllocCounter;
- (void)increaseDeallocCounter;
- (void)decreaseDeallocCounter;

- (long long)allocCounter;
- (long long)deallocCounter;
- (long long)inUseCounter;
@end

