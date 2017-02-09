//
//  UMObjectDebug.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

/* Important: THIS FILE MUST BE COMPILED WITH -fno-objc-arc  !*/

#import "UMObjectDebug.h"

@implementation UMObjectDebug

- (id) init
{
    self = [super init];
    if(self)
    {
        ulib_retain_counter=1;
        umobject_flags |= UMOBJECT_FLAG_LOG_RETAIN_RELEASE;
    }
    return self;
}

- (id)retain
{
    [super retain];
    ulib_retain_counter++;
    [self retainDebug];
    return self;
}

- (oneway void)release
{
    ulib_retain_counter--;
    [self releaseDebug];
    [super release];
}

- (void)retainDebug
{
    ulib_retain_counter++;
    if(umobject_flags  & UMOBJECT_FLAG_LOG_RETAIN_RELEASE)
    {
        NSLog(@"Retain [%p] rc=%d",self,ulib_retain_counter);
    }
}


- (void)releaseDebug
{
    if(umobject_flags  & UMOBJECT_FLAG_LOG_RETAIN_RELEASE)
    {
        NSLog(@"Release [%p] rc=%d",self,ulib_retain_counter);
    }
}

- (void)dealloc
{
    if(umobject_flags  & UMOBJECT_FLAG_LOG_RETAIN_RELEASE)
    {
        NSLog(@"Dealloc [%p] rc=%d",self,ulib_retain_counter);
    }
    [super dealloc];
}

- (void)enableRetainReleaseLogging
{
    umobject_flags |= UMOBJECT_FLAG_LOG_RETAIN_RELEASE;
}
@end


