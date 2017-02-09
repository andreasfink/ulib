//
//  UMReadWriteLock.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#ifndef LINUX

#include <pthread.h>
#import <Foundation/Foundation.h>
#import "UMObject.h"

@interface UMReadWriteLock : UMObject
{
@private
	pthread_rwlock_t	rwLock;
	
}

- (id)init;
- (void)readLock;
- (void)writeLock;
- (int)tryReadLock;
- (int)tryWriteLock;
- (void)unlock;

@end

#endif
