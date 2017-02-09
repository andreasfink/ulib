//
//  UMLock.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"
#include <sys/types.h>
#include <pthread.h>

#define MAX_LOCK_EVENTS 10

extern NSMutableArray *global_umlock_registry;

uint64_t 	ulib_get_thread_id(void);
NSString	*ulib_get_thread_name(pthread_t thread);    /* returns the name of a specific thread */
void        ulib_set_thread_name(NSString *name);       /* sets the name of the current thread */

@class UMLockEvent;

@interface UMLock : UMObject
{
    BOOL                recursive;
    NSRecursiveLock     *_rlock; /* reentrant lock      */
    NSLock              *_nrlock; /* non reentrant lock */
    /* only one of them is existing */
    UMLockEvent *lock_events[MAX_LOCK_EVENTS];
    BOOL        isLocked;
    uint64_t    locking_thread_tid;
    int         lock_count;
    BOOL        use_event_logging;      /* defaults to YES for CONFIG_DEBUG */
    BOOL        use_backtrace_in_event_logging;
    BOOL        warn_for_nested_locks;  /* defaults to YES */
}

@property (readwrite,assign)    BOOL        isLocked;
@property (readwrite,assign)    uint64_t    locking_thread_tid;
@property (readwrite,assign)    int         lock_count;
@property (readwrite,assign)    BOOL        use_event_logging;
@property (readwrite,assign)    BOOL        use_backtrace_in_event_logging;
@property (readwrite,assign)    BOOL        warn_for_nested_locks;
@property (readonly,assign)     BOOL        recursive;


- (id)initReentrant;
- (id)initNonReentrant;

- (id)initNonReentrantWithFile:(const char *)file line:(long)line function:(const char *)func;
- (id)initReentrantWithFile:(const char *)file line:(long)line function:(const char *)func;

- (void)lock;
- (void)unlock;

- (void)lockAtFile:(const char *)file line:(long)line function:(const char *)func;
- (void)unlockAtFile:(const char *)file line:(long)line function:(const char *)func;
- (BOOL)isUnlocked;

+ (void)registerLock:(UMLock *)lock;
+ (void)unregisterLock:(UMLock *)lock;

- (void)addEvent:(UMLockEvent *)event;

@end


#define UMLOCK(a)           [a lockAtFile:__FILE__ line:__LINE__ function:__func__]
#define UMUNLOCK(a)         [a unlockAtFile:__FILE__ line:__LINE__ function:__func__]

#define UMLOCK_CREATE_NONREENTRANT()    [[UMLock alloc]initNonReentrantWithFile:__FILE__ line:__LINE__ function:__func__];
#define UMLOCK_CREATE_REENTRANT()       [[UMLock alloc]initReentrantWithFile:__FILE__ line:__LINE__ function:__func__];
#define UMLOCK_DESTROY(a)   { [UMLock unregisterLock:a]; a=NULL; }

void umlock_init(void);
void nslock_nested_lock_warning(UMLock *lock);
