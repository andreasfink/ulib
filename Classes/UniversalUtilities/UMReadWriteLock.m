//
//  UMReadWriteLock.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#ifndef LINUX
/* not supported under LINUX */

#import "UMReadWriteLock.h"

@implementation UMReadWriteLock

- (id)init
{
    self=[super init];
    if(self)
	{
		pthread_rwlock_init(&self->rwLock, NULL);
	}
	return self;
}

- (void)dealloc
{
	pthread_rwlock_destroy(&rwLock);
}

- (void)readLock
{
	pthread_rwlock_rdlock(&rwLock);
}

- (void)writeLock
{
	pthread_rwlock_wrlock(&rwLock);
}

- (int)tryReadLock
{
	return pthread_rwlock_tryrdlock(&rwLock);
}

- (int)tryWriteLock
{
	return pthread_rwlock_trywrlock(&rwLock);
}

- (void)unlock
{
	pthread_rwlock_unlock(&rwLock);
}

@end

#endif

