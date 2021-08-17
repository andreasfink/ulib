//
//  UMThreadHelpers.m
//  ulib
//
//  Created by Andreas Fink on 22.11.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMThreadHelpers.h"

#if defined(LINUX)

#define _GNU_SOURCE
#include <pthread.h>
#include <sys/prctl.h>
int pthread_setname_np(pthread_t thread, const char *name);
int pthread_getname_np(pthread_t thread, char *name, size_t len);

#else
#include <pthread.h>
#endif

void        ulib_set_thread_name(NSString *name)
{
    @autoreleasepool
    {
        if(name==NULL)
        {
            return;
        }
    #if defined(__APPLE__)
        pthread_setname_np([name UTF8String]);
    #elif defined(LINUX)
        pthread_t thread_id;
        thread_id = pthread_self();
        pthread_setname_np(thread_id, [name UTF8String]);
        prctl(PR_SET_NAME,[name UTF8String],0,0,0);
    #elif defined(FREEBSD)
    #warning  ulib_set_thread_name() is to be implemented for this Platform
    #endif
    }
}
