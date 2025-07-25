//
//  UMMutex.h
//  ulib
//
//  Created by Andreas Fink on 11.11.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/framework.h>
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
    const char          *_lastUnockedInFile;
    long                 _lastUnockedAtLine;
    const char          *_lastUnlockedInFunction;
    const char          *_tryingToLockInFile;
    long                 _tryingToLockAtLine;
    const char          *_tryingToLockInFunction;
    BOOL                _isLocked;

}

@property(readwrite,strong) NSString        *name;
@property(readwrite,assign) const char      *lockedInFile;
@property(readwrite,assign) long            lockedAtLine;
@property(readwrite,assign) const char      *lockedInFunction;
@property(readwrite,assign) const char      *lastLockedInFile;
@property(readwrite,assign) long            lastLockedAtLine;
@property(readwrite,assign) const char      *lastLockedInFunction;
@property(readwrite,assign) const char      *lastUnlockedInFile;
@property(readwrite,assign) long            lastUnlockedAtLine;
@property(readwrite,assign) const char      *lastUnlockedInFunction;
@property(readwrite,assign) const char      *tryingToLockInFile;
@property(readwrite,assign) long            tryingToLockAtLine;
@property(readwrite,assign) const char      *tryingToLockInFunction;
@property(readonly,assign) BOOL             isLocked;
@property(readonly,assign) int              lockDepth;


/*
 USE MACROS ummutex_lock(mutex), ummutex_trylock(mutex) and ummutex_unlock(mutex) instead now
- (void) lock;
- (void) unlock;
- (int) tryLock;
*/
- (void) _internalLock;
- (void) _internalUnlock;
- (int)  _internalTryLock;
- (int)  _internalTryLock:(NSTimeInterval)timeout
                retryTime:(NSTimeInterval)retryTime;

/*- (int)tryLock:(NSTimeInterval)timeout
     retryTime:(NSTimeInterval)retryTime;
*/
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
@property(readwrite,strong,atomic)  NSMutableArray <UMMutex *>*mutexes;


@end



BOOL ummutex_stat_is_enabled(void);
NSArray *ummutex_stat(BOOL sortByName);
int ummutex_stat_enable(void);
void ummutex_stat_disable(void);
void ummutex_add_locked_mutex(UMMutex *m);
void ummutex_remove_locked_mutex(UMMutex *m);
NSArray *ummutex_get_locked_mutexes(void);
void ummutex_record_locks(void);


void ummutex_lock_flf(UMMutex *mutex,const char *file,long line, const char *func);
void ummutex_unlock_flf(UMMutex *mutex,const char *file,long line, const char *func);
int ummutex_trylock_flf(UMMutex *mutex,const char *file,long line, const char *func);
int ummutex_trylock_retry_timeout_retrytime_flf(UMMutex *mutex,NSTimeInterval timeout,NSTimeInterval retry,const char *file,long line, const char *func);

#ifndef __FUNCTION__
#define __FUNCTION__ __func__
#endif

#ifndef __func__
#define __func__ "unknown"
#endif

#define  ummutex_lock(mutex)                                                ummutex_lock_flf(mutex,__FILE__,__LINE__,__func__)
#define  ummutex_unlock(mutex)                                              ummutex_unlock_flf(mutex,__FILE__,__LINE__,__func__)
#define  ummutex_trylock(mutex)                                             ummutex_trylock_flf(mutex,__FILE__,__LINE__,__func__)
#define  ummutex_trylock_retry_timeout_retrytime(mutex,timeout,retrytime) ummutex_trylock_retry_timeout_retrytime_flf(mutex,timeout,retry,__FILE__,__LINE__,__func__)
