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
		_lock = [[NSLock alloc]init];
	}
	return self;
}

- (void)increaseAllocCounter
{
	NSLOCK_LOCK(_lock);
	_allocCounter++;
	_inUseCounter++;
	NSLOCK_UNLOCK(_lock);
}

- (void)decreaseAllocCounter
{
	NSLOCK_LOCK(_lock);
	_allocCounter--;
	_inUseCounter--;
	NSLOCK_UNLOCK(_lock);
}

- (void)increaseDeallocCounter
{
	NSLOCK_LOCK(_lock);
	_deallocCounter++;
	_inUseCounter--;
	NSLOCK_UNLOCK(_lock);
}

- (void)decreaseDeallocCounter
{
	NSLOCK_LOCK(_lock);
	_deallocCounter--;
	_inUseCounter++;
	NSLOCK_UNLOCK(_lock);
}

- (long long)allocCounter
{
	long long l;

	NSLOCK_LOCK(_lock);
	l = _allocCounter;
	NSLOCK_UNLOCK(_lock);
	return l;
}

- (long long)deallocCounter
{
	long long l;

	NSLOCK_LOCK(_lock);
	l = _deallocCounter;
	NSLOCK_UNLOCK(_lock);
	return l;
}

- (long long)inUseCounter
{
	long long l;

	NSLOCK_LOCK(_lock);
	l = _inUseCounter;
	NSLOCK_UNLOCK(_lock);
	return l;
}

- (void) dealloc
{
	_name = "\0";
}

- (UMObjectStatisticEntry *)copyWithZone:(NSZone *)zone
{
	NSLOCK_LOCK(_lock);

	UMObjectStatisticEntry *clone = [[UMObjectStatisticEntry allocWithZone:zone]init];
	clone->_allocCounter = _allocCounter;
	clone->_deallocCounter = _deallocCounter;
	clone->_inUseCounter = _inUseCounter;
	clone->_name = _name;

	NSLOCK_UNLOCK(_lock);
	return clone;
}
@end
