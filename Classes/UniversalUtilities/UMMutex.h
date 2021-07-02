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
}

@property(readwrite,strong) NSString        *name;
@property(readwrite,assign) const char      *lockedInFile;
@property(readwrite,assign) long            lockedAtLine;
@property(readwrite,assign) const char      *lockedInFunction;

- (void)lock;
- (void)unlock;
- (int)tryLock;
- (UMMutex *)init;
- (UMMutex *)initWithName:(NSString *)name;
- (UMMutex *)initWithName:(NSString *)name saveInObjectStat:(BOOL)safeInObjectStat;
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
    [a lock]; \
    a.lockedInFile = __FILE__;  \
    a.lockedAtLine = __LINE__;   \
    a.lockedInFunction =  __func__;  \
}

#define UMMUTEX_UNLOCK(a) \
{  \
    a.lockedInFunction =  NULL; \
    [a unlock];  \
}
