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
    pthread_mutex_t *_mutexLock;
    pthread_mutexattr_t *_mutexAttr;
    int _lockDepth;
    NSString *_name;
}

@property(readwrite,strong) NSString *name;
- (void)lock;
- (void)unlock;
- (int)tryLock;
- (UMMutex *)initWithName:(NSString *)name;
@end

@interface UMMutexStat : NSObject
{
    NSString *_name;
    int64_t _lock_count;
    int64_t _trylock_count;
    int64_t _unlock_count;
    int64_t _waiting_count;
    BOOL _currently_locked;
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
int umutex_stat_enable(void);
void ummutex_stat_disable(void);
