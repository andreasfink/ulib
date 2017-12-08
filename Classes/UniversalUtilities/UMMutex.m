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
        _mutexAttr = (pthread_mutexattr_t *)malloc(sizeof(pthread_mutexattr_t));
        if(_mutexAttr == NULL)
        {
            free(_mutexLock);
            _mutexAttr = NULL;
            _mutexLock = NULL;
            return NULL;
        }
        pthread_mutexattr_init(_mutexAttr);
        pthread_mutexattr_settype(_mutexAttr, PTHREAD_MUTEX_RECURSIVE);
        pthread_mutex_init(_mutexLock, _mutexAttr);
    }
    return self;
}

- (void) dealloc
{
    if(_mutexLock)
    {
        pthread_mutex_lock(_mutexLock);
        pthread_mutex_t *_mutexLock2 = _mutexLock;
        _mutexLock = NULL;
        if(_mutexAttr)
        {
            pthread_mutexattr_destroy(_mutexAttr);
            free(_mutexAttr);
            _mutexAttr = NULL;
        }
        pthread_mutex_unlock(_mutexLock2);
        if(_mutexLock2)
        {
            pthread_mutex_destroy(_mutexLock2);
            free(_mutexLock2);
        }
    }
}

- (void)lock
{
    if(_mutexLock)
    {
        pthread_mutex_lock(_mutexLock);
        _lockDepth++;
    }
}

- (void)unlock
{
    if(_mutexLock)
    {
        _lockDepth--;
        pthread_mutex_unlock(_mutexLock);
    }
}

- (int)tryLock /* returns 0 if success ful */
{
    if(_mutexLock)
    {
        int r = pthread_mutex_trylock(_mutexLock);
        if(r==0)
        {
            _lockDepth++;
        }
        return r;
    }
    return -1;
}

@end

