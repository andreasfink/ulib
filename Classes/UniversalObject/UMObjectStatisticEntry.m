//
//  UMObjectStatisticEntry.m
//  ulib
//
//  Created by Andreas Fink on 09.05.19.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObjectStatisticEntry.h"

#define NSLOCK_LOCK(l)     [l lock];
#define NSLOCK_UNLOCK(l)   [l unlock];

@implementation UMObjectStatisticEntry

- (UMObjectStatisticEntry *)init
{
	self = [super init];
	if(self)
	{
		_entryLock = [[NSLock alloc]init];
	}
	return self;
}

- (void)increaseAllocCounter
{
	NSLOCK_LOCK(_entryLock);
	_allocCounter++;
	_inUseCounter++;
	NSLOCK_UNLOCK(_entryLock);
}

- (void)decreaseAllocCounter
{
	NSLOCK_LOCK(_entryLock);
	_allocCounter--;
	_inUseCounter--;
	NSLOCK_UNLOCK(_entryLock);
}

- (void)increaseDeallocCounter
{
	NSLOCK_LOCK(_entryLock);
	_deallocCounter++;
	_inUseCounter--;
	NSLOCK_UNLOCK(_entryLock);
}

- (void)decreaseDeallocCounter
{
	NSLOCK_LOCK(_entryLock);
	_deallocCounter--;
	_inUseCounter++;
	NSLOCK_UNLOCK(_entryLock);
}

- (long long)allocCounter
{
	long long l;

	NSLOCK_LOCK(_entryLock);
	l = _allocCounter;
	NSLOCK_UNLOCK(_entryLock);
	return l;
}

- (long long)deallocCounter
{
	long long l;

	NSLOCK_LOCK(_entryLock);
	l = _deallocCounter;
	NSLOCK_UNLOCK(_entryLock);
	return l;
}

- (long long)inUseCounter
{
	long long l;

	NSLOCK_LOCK(_entryLock);
	l = _inUseCounter;
	NSLOCK_UNLOCK(_entryLock);
	return l;
}

- (void) dealloc
{
	_name = "\0";
}

- (UMObjectStatisticEntry *)copyWithZone:(NSZone *)zone
{
	NSLOCK_LOCK(_entryLock);

	UMObjectStatisticEntry *clone = [[UMObjectStatisticEntry allocWithZone:zone]init];
	clone->_allocCounter = _allocCounter;
	clone->_deallocCounter = _deallocCounter;
	clone->_inUseCounter = _inUseCounter;
	clone->_name = _name;

	NSLOCK_UNLOCK(_entryLock);
	return clone;
}
@end
