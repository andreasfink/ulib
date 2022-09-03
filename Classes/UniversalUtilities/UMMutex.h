//
//  UMMutex.h
//  ulib
//
//  Created by Andreas Fink on 11.11.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>
#import <pthread.h>


@interface UMMutex : NSObject
{
    pthread_mutex_t     _mutexLock;
    pthread_mutexattr_t _mutexAttr;
    int                 _lockDepth;
    NSString            *_name;
    const char          *_objectStatisticsName;
    BOOL                _savedInObjectStat;
    const char          *_lockedInFile;
    long                 _lockedAtLine;
    const char          *_lockedInFunction;
    const char          *_lastLockedInFile;
    long                 _lastLockedAtLine;
    const char          *_lastLockedInFunction;
    const char          *_tryingToLockInFile;
    long                 _tryingToLockAtLine;
    const char          *_tryingToLockInFunction;

}

@property(readwrite,strong) NSString        *name;
@property(readwrite,assign) const char      *lockedInFile;
@property(readwrite,assign) long            lockedAtLine;
@property(readwrite,assign) const char      *lockedInFunction;
@property(readwrite,assign) const char      *lastLockedInFile;
@property(readwrite,assign) long            lastLockedAtLine;
@property(readwrite,assign) const char      *lastLockedInFunction;
@property(readwrite,assign) const char      *tryingToLockInFile;
@property(readwrite,assign) long            tryingToLockAtLine;
@property(readwrite,assign) const char      *tryingToLockInFunction;


- (void) lock;
- (void) unlock;
- (int) tryLock;
- (int)tryLock:(NSTimeInterval)timeout
     retryTime:(NSTimeInterval)retryTime;

- (UMMutex *) init;
- (UMMutex *) initWithName:(NSString *)name;
- (UMMutex *) initWithName:(NSString *)name saveInObjectStat:(BOOL)safeInObjectStat;
- (NSString *) lockStatusDescription;
@end

@interface UMMutexStat : NSObject
{
    NSString *_name;
    int64_t _lock_count;
    int64_t _trylock_count;
    int64_t _unlock_count;
    int64_t _waiting_count;
    BOOL    _currently_locked;
}

@property(readwrite,strong,atomic)  NSString *name;
@property(readwrite,assign,atomic)  int64_t lock_count;
@property(readwrite,assign,atomic)  int64_t trylock_count;
@property(readwrite,assign,atomic)  int64_t unlock_count;
@property(readwrite,assign,atomic)  int64_t waiting_count;
@property(readwrite,assign,atomic)  BOOL currently_locked;

@end



BOOL ummutex_stat_is_enabled(void);
NSArray *ummutex_stat(BOOL sortByName);
int ummutex_stat_enable(void);
void ummutex_stat_disable(void);

#define UMMUTEX_LOCK(a)  \
{ \
    a.tryingToLockInFile = __FILE__; \
    a.tryingToLockAtLine = __LINE__; \
    a.tryingToLockInFunction = __func__; \
    [a lock]; \
    a.lockedInFile = __FILE__;  \
    a.lockedAtLine = __LINE__;   \
    a.lockedInFunction =  __func__;  \
    a.tryingToLockInFile = NULL; \
    a.tryingToLockAtLine = 0; \
    a.tryingToLockInFunction = NULL; \
}

#define UMMUTEX_TRYLOCK(a,timeout,retry,result)  \
{ \
    a.tryingToLockInFile = __FILE__; \
    a.tryingToLockAtLine = __LINE__; \
    a.tryingToLockInFunction = __func__; \
    if(timeout <= 0) \
    { \
        result = [a tryLock];\
    } \
    else \
    { \
        result = [a tryLock:timeout retryTime:retry];\
    } \
    if(result==0) \
    { \
        a.lockedInFile = __FILE__;  \
        a.lockedAtLine = __LINE__;   \
        a.lockedInFunction =  __func__;  \
    } \
    else \
    { \
        a.tryingToLockInFile = NULL; \
        a.tryingToLockAtLine = 0; \
        a.tryingToLockInFunction = NULL; \
    } \
}


#define UMMUTEX_UNLOCK(a) \
{  \
    a.lastLockedInFile = a.lockedInFile;  \
    a.lastLockedAtLine = a.lockedAtLine;   \
    a.lastLockedInFunction =  a.lockedInFunction;  \
    a.lockedInFunction =  NULL; \
    [a unlock];  \
}

