//
//  UMThreadHelpers.m
//  ulib
//
//  Created by Andreas Fink on 22.11.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMThreadHelpers.h"

#include <pthread.h>

void        ulib_set_thread_name(NSString *name)
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
#endif
}
