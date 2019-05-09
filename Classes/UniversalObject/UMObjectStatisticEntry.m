//
//  UMObjectStatisticEntry.m
//  ulib
//
//  Created by Andreas Fink on 09.05.19.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObjectStatisticEntry.h"

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
	[_lock lock];
	_allocCounter++;
	_inUseCounter++;
	[_lock unlock];
}

- (void)decreaseAllocCounter
{
	[_lock lock];
	_allocCounter--;
	_inUseCounter--;
	[_lock unlock];
}

- (void)increaseDeallocCounter
{
	[_lock lock];
	_deallocCounter++;
	_inUseCounter--;
	[_lock unlock];
}

- (void)decreaseDeallocCounter
{
	[_lock lock];
	_deallocCounter--;
	_inUseCounter++;
	[_lock unlock];
}

- (long long)allocCounter
{
	long long l;

	[_lock lock];
	l = _allocCounter;
	[_lock unlock];
	return l;
}

- (long long)deallocCounter
{
	long long l;

	[_lock lock];
	l = _deallocCounter;
	[_lock unlock];
	return l;
}

- (long long)inUseCounter
{
	long long l;

	[_lock lock];
	l = _inUseCounter;
	[_lock unlock];
	return l;
}

- (void) dealloc
{
	_name = "\0";
}

- (UMObjectStatisticEntry *)copyWithZone:(NSZone *)zone
{
	[_lock lock];

	UMObjectStatisticEntry *clone = [[UMObjectStatisticEntry allocWithZone:zone]init];
	clone->_allocCounter = _allocCounter;
	clone->_deallocCounter = _deallocCounter;
	clone->_inUseCounter = _inUseCounter;
	clone->_name = _name;

	[_lock unlock];
	return clone;
}
@end
