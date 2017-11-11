//
//  UMMutex.m
//  ulib
//
//  Created by Andreas Fink on 11.11.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMMutex.h"

@implementation UMMutex


- (UMMutex *)init
{
    self = [super init];
    if(self)
    {
        _mutexLock = (pthread_mutex_t *)malloc(sizeof(pthread_mutex_t));
        if(_mutexLock == NULL)
        {
            return NULL;
        }
        pthread_mutex_init(_mutexLock, NULL);
    }
    return self;
}

- (void) dealloc
{
    if(_mutexLock)
    {
        pthread_mutex_destroy(_mutexLock);
        free(_mutexLock);
        _mutexLock = NULL;
    }
}

- (void)lock
{
    if(_mutexLock)
    {
        pthread_mutex_lock(_mutexLock);
    }
}

- (void)unlock
{
    if(_mutexLock)
    {
        pthread_mutex_unlock(_mutexLock);
    }
}

- (int)tryLock /* returns 0 if success ful */
{
    if(_mutexLock)
    {
        return pthread_mutex_trylock(_mutexLock);
    }
    return -1;
}

@end

