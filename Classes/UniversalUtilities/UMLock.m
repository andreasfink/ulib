//
//  UMLock.m
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#import "UMLock.h"
#import "UMUtil.h"
#import "UMLockEvent.h"

#import <pthread.h>

#if defined(LINUX)

#include <sys/types.h>
#include "unistd.h"
#include <sys/syscall.h>
#include <sys/prctl.h>
extern int pthread_setname_np (pthread_t __target_thread, __const char *__name);

uint64_t ulib_get_thread_id(void)
{
	uint64_t tid = (uint64_t)syscall (SYS_gettid);
	return tid;
}

#elif defined(__APPLE__)

uint64_t ulib_get_thread_id(void)
{
    uint64_t tid = 0;
    pthread_t me = pthread_self();
    pthread_threadid_np(me,&tid);
    return tid;
}
#else

#error	We need gettid()

#endif


#if defined(LINUX) || defined(__APPLE__)
extern int pthread_getname_np (pthread_t thread, char *buf,size_t len);
NSString *ulib_get_thread_name(pthread_t thread)
{
    char name[256];
    memset(name,0x00,256);
    pthread_getname_np (thread, &name[0],255);
    return [NSString stringWithUTF8String:name];
}
#else
#error We need something like pthread_getname_np defined
#endif


#define THREAD_KEY_DUMMY_VALUE      -1234

static pthread_key_t    thread_specific_key = THREAD_KEY_DUMMY_VALUE;

void umlock_init(void)
{
    if(thread_specific_key==THREAD_KEY_DUMMY_VALUE)
    {
        pthread_key_create(&thread_specific_key, NULL);
    }
}


static uint64_t umlock_get_thread_id(void)
{
    return ulib_get_thread_id();
#if 0
    if(thread_specific_key==THREAD_KEY_DUMMY_VALUE)
    {
        pthread_key_create(&thread_specific_key, NULL);
    }
    uint64_t tid = (uint64_t)pthread_getspecific(thread_specific_key);
    if(tid==0)
    {
        tid =ulib_get_thread_id();
        pthread_setspecific(thread_specific_key,(void *)tid);
    }
    return tid;
#endif
}


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

NSMutableArray *global_umlock_registry = NULL;

/* We put this into a C function for easier debugging tracking as you can simply set a break point to it
 lldb> break set -b nslock_nested_lock_warning
*/

void nslock_nested_lock_warning(UMLock *lock)
{
    if(lock.warn_for_nested_locks)
    {
        NSLog(@"**Warning nested lock**\n%@\n***********************\n",[lock description]);
    }
}

@implementation UMLock

@synthesize recursive;
@synthesize isLocked;
@synthesize lock_count;
@synthesize locking_thread_tid;
@synthesize use_event_logging;
@synthesize warn_for_nested_locks;
@synthesize use_backtrace_in_event_logging;

- (BOOL)isUnlocked
{
	return !isLocked;
}
- (id)init
{
    return [self initReentrant];
}

- (id)initReentrant
{
    return [self initReentrantWithFile:__FILE__ line:__LINE__ function:__func__];
}

- (id)initNonReentrant
{
    return [self initNonReentrantWithFile:__FILE__ line:__LINE__ function:__func__];
}

- (id)initNonReentrantWithFile:(const char *)file line:(long)line function:(const char *)func
{
    self = [super init];
    if(self)
    {
        recursive = NO;
        use_event_logging = NO;
        use_backtrace_in_event_logging = NO;
        warn_for_nested_locks = YES;
        if(use_event_logging)
        {
            uint64_t    tid = umlock_get_thread_id();
            NSString *name = ulib_get_thread_name(pthread_self());
            UMLockEvent *event = [[UMLockEvent alloc] initFromFile:file line:line function:func action:"init" threadId:tid threadName:name bt:use_backtrace_in_event_logging];
            [self addEvent:event];
        }
        _nrlock = [[NSLock alloc]init];
        _rlock = NULL;
    }
    return self;
}

- (id)initReentrantWithFile:(const char *)file line:(long)line function:(const char *)func
{
    self = [super init];
    if(self)
    {
        recursive = YES;
        use_event_logging = NO;
        use_backtrace_in_event_logging = NO;
        warn_for_nested_locks = YES;
        if(use_event_logging)
        {
            uint64_t    tid = umlock_get_thread_id();
            NSString *name = ulib_get_thread_name(pthread_self());
            UMLockEvent *event = [[UMLockEvent alloc] initFromFile:file line:line function:func action:"init" threadId:tid threadName:name bt:use_backtrace_in_event_logging];
            [self addEvent:event];
        }
        _nrlock = NULL;
        _rlock = [[NSRecursiveLock alloc]init];
    }
    return self;
}


- (void)lock
{
    [self lockAtFile:__FILE__ line:__LINE__ function:__func__];
}

- (void)lockAtFile:(const char *)file line:(long)line function:(const char *)func
{
    uint64_t    tid = umlock_get_thread_id();

    if(recursive)
    {
        [_rlock lock];
    }
    else
    {
        [_nrlock lock];
    }
    lock_count++;
    locking_thread_tid = tid;
    
    if(use_event_logging)
    {
        NSString *name = ulib_get_thread_name(pthread_self());
        UMLockEvent *event;
        
        if(lock_count == 1)
        {
            event = [[UMLockEvent alloc] initFromFile:file line:line function:func action:"lock" threadId:tid threadName:name bt:use_backtrace_in_event_logging];
        }
        else
        {
            event = [[UMLockEvent alloc] initFromFile:file line:line function:func action:"lock (nested)" threadId:tid threadName:name bt:use_backtrace_in_event_logging];
            nslock_nested_lock_warning(self);
        }
        [self addEvent:event];
   }
   isLocked = YES;
}

- (void)unlock
{
    [self unlockAtFile:__FILE__ line:__LINE__ function:__func__];
}

- (void)unlockAtFile:(const char *)file line:(long)line function:(const char *)func
{
    uint64_t tid = umlock_get_thread_id();
    lock_count--;
    
    if(use_event_logging)
    {
        NSString *name = ulib_get_thread_name(pthread_self());
        UMLockEvent *event;

        if(lock_count == 0)
        {
            event = [[UMLockEvent alloc] initFromFile:file line:line function:func action:"unlock" threadId:tid threadName:name bt:use_backtrace_in_event_logging];
        }
        else
        {
            event = [[UMLockEvent alloc] initFromFile:file line:line function:func action:"unlock (nested)" threadId:tid threadName:name bt:use_backtrace_in_event_logging];
            nslock_nested_lock_warning(self);
        }
        [self addEvent:event];
    }
    
    isLocked = NO;
    locking_thread_tid = -100;

    if(recursive)
    {
        [_rlock unlock];
    }
    else
    {
        [_nrlock unlock];
    }
}

+ (void)initRegistry
{
    if(global_umlock_registry==NULL)
    {
        global_umlock_registry = [[NSMutableArray alloc]init];
    }
}

+ (void)registerLock:(UMLock *)thisLock
{
    if(global_umlock_registry==NULL)
    {
        global_umlock_registry = [[NSMutableArray alloc]init];
    }
    @synchronized(global_umlock_registry)
    {
        [global_umlock_registry addObject:thisLock];
    }
}

+ (void)unregisterLock:(UMLock *)thisLock
{
    @synchronized(global_umlock_registry)
    {
        if(thisLock)
        {
            [global_umlock_registry removeObject:thisLock];
        }
    }
}

- (void)addEvent:(UMLockEvent *)event
{
   if(event)
   {
       int i;
       for(i=1;i<MAX_LOCK_EVENTS-1;i++)
       {
           lock_events[i] = lock_events[i-1];
       }
       lock_events[0] = event;
   }
}

- (NSString *)description
{
    NSMutableString *s = [[NSMutableString alloc]init];
    
    
    [s appendFormat:@"%@\n",[super description]];
    [s appendFormat:@"nrlock: %@\n",[_nrlock description]];
    [s appendFormat:@"rlock: %@\n",[_rlock description]];
    [s appendFormat:@"isLocked: %@\n",isLocked ? @"YES" : @"NO"];
    [s appendFormat:@"locking_thread_tid: %lld\n",(long long)locking_thread_tid];
    [s appendFormat:@"lock_count: %d\n",lock_count];
    int i;
    for(i=0;i<MAX_LOCK_EVENTS;i++)
    {
        if(lock_events[i])
        {
            NSString *m = [lock_events[i] descriptionWithPrefix:@"    "];
            if(m)
            {
                [s appendFormat:@"event[%d]:\n%@",i,m];
            }
        }
    }
    return s;
}

@end
