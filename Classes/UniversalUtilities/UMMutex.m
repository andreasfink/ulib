//
//  UMMutex.m
//  ulib
//
//  Created by Andreas Fink on 11.11.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMMutex.h"
#import "UMObjectStatistic.h"
#import "UMConstantStringsDict.h"

static NSMutableDictionary *global_ummutex_stat = NULL;
static pthread_mutex_t *global_ummutex_stat_mutex = NULL;

@implementation UMMutexStat
- (UMMutexStat *)copyWithZone:(NSZone *)zone;
{
    UMMutexStat *r = [[UMMutexStat allocWithZone:zone]init];
    r.name = _name;
    r.lock_count = _lock_count;
    r.trylock_count = _trylock_count;
    r.unlock_count = _unlock_count;
    r.currently_locked = _currently_locked;
    return r;
}

@end

@implementation UMMutex

- (UMMutex *)init
{
    return [self initWithName:@"unnamed" saveInObjectStat:YES];
}

- (UMMutex *)initWithName:(NSString *)name
{
    return [self initWithName:name saveInObjectStat:YES];
}

- (UMMutex *)initWithName:(NSString *)name saveInObjectStat:(BOOL)saveInObjectStat
{
    self = [super init];
    if(self)
    {
        _name = name;
        _savedInObjectStat = saveInObjectStat;
        memset(&_mutexLock,0x00,sizeof(_mutexLock));
        memset(&_mutexAttr,0x00,sizeof(_mutexAttr));
        pthread_mutexattr_init(&_mutexAttr);
        pthread_mutexattr_settype(&_mutexAttr, PTHREAD_MUTEX_RECURSIVE);
        pthread_mutex_init(&_mutexLock, &_mutexAttr);

        if(_savedInObjectStat)
        {
            UMObjectStatistic *stat = [UMObjectStatistic sharedInstance];
            NSString *s = [NSString stringWithFormat:@"UMMutex(%@)",name];
            UMConstantStringsDict *magicNames   = [UMConstantStringsDict sharedInstance];
            _objectStatisticsName    = [magicNames asciiStringFromNSString:s];
            [stat increaseAllocCounter:_objectStatisticsName];
        }
        if(global_ummutex_stat)
        {
            pthread_mutex_lock(global_ummutex_stat_mutex);
            UMMutexStat *stat = global_ummutex_stat[name];
            if(stat!=NULL)
            {
                int i=2;
                NSString *name2 = [NSString stringWithFormat:@"%@_%d",name,i];
                while(global_ummutex_stat[name2]!=NULL)
                {
                    i++;
                    name2 = [NSString stringWithFormat:@"%@_%d",name,i];
                }
                _name = name2;
                stat = [[UMMutexStat alloc]init];
                stat.name = name2;
                global_ummutex_stat[_name] = stat;
            }
            else
            {
                _name = name;
                stat = [[UMMutexStat alloc]init];
                stat.name = name;
                global_ummutex_stat[_name] = stat;
            }
            pthread_mutex_unlock(global_ummutex_stat_mutex);
        }
    }
    return self;
}

- (void) dealloc
{
    if((_savedInObjectStat) && (_objectStatisticsName))
    {
        UMObjectStatistic *stat = [UMObjectStatistic sharedInstance];
        [stat increaseDeallocCounter:_objectStatisticsName];
    }
    pthread_mutex_destroy(&_mutexLock);
    pthread_mutexattr_destroy(&_mutexAttr);
    memset(&_mutexLock,0x00,sizeof(_mutexLock));
    memset(&_mutexAttr,0x00,sizeof(_mutexAttr));
    if(global_ummutex_stat)
    {
        pthread_mutex_lock(global_ummutex_stat_mutex);
        [global_ummutex_stat removeObjectForKey:_name];
        pthread_mutex_unlock(global_ummutex_stat_mutex);
    }
}

- (void)lock
{
    UMMutexStat *stat = NULL;
    if(global_ummutex_stat)
    {
        pthread_mutex_lock(global_ummutex_stat_mutex);
        stat = global_ummutex_stat[_name];
        if(stat==NULL)
        {
            stat = [[UMMutexStat alloc]init];
            stat.name = _name;
            global_ummutex_stat[_name] = stat;
        }
        stat.waiting_count++;
        pthread_mutex_unlock(global_ummutex_stat_mutex);
    }

    pthread_mutex_lock(&_mutexLock);
    _lockDepth++;

    if(global_ummutex_stat)
    {
        pthread_mutex_lock(global_ummutex_stat_mutex);
        stat.lock_count++;
        stat.waiting_count--;
        stat.currently_locked = YES;
        pthread_mutex_unlock(global_ummutex_stat_mutex);
    }
}

- (void)unlock
{
    if(global_ummutex_stat)
    {
        pthread_mutex_lock(global_ummutex_stat_mutex);
        UMMutexStat *stat = global_ummutex_stat[_name];
        if(stat==NULL)
        {
            stat = [[UMMutexStat alloc]init];
            stat.name = _name;
            global_ummutex_stat[_name] = stat;
        }
        stat.unlock_count++;
        stat.currently_locked = NO;
        pthread_mutex_unlock(global_ummutex_stat_mutex);
    }
    _lockDepth--;
    pthread_mutex_unlock(&_mutexLock);
}

- (int)tryLock /* returns 0 if success ful */
{
    UMMutexStat *stat;
    if(global_ummutex_stat)
    {
        pthread_mutex_lock(global_ummutex_stat_mutex);
        stat = global_ummutex_stat[_name];
        if(stat==NULL)
        {
            stat = [[UMMutexStat alloc]init];
            stat.name = _name;
            global_ummutex_stat[_name] = stat;
        }
        pthread_mutex_unlock(global_ummutex_stat_mutex);
    }

    int r = pthread_mutex_trylock(&_mutexLock);
    if(r==0)
    {
        _lockDepth++;
    }
    if(global_ummutex_stat)
    {
        pthread_mutex_lock(global_ummutex_stat_mutex);
        if(r==0)
        {
            stat.currently_locked = YES;
            stat.lock_count++;
        }
        else
        {
            stat.trylock_count++;
        }
        pthread_mutex_unlock(global_ummutex_stat_mutex);
    }
    return r;
}

@end



int ummutex_stat_enable(void)
{
    if(global_ummutex_stat == NULL)
    {
        global_ummutex_stat_mutex = (pthread_mutex_t *)malloc(sizeof(pthread_mutex_t));
        if(global_ummutex_stat_mutex)
        {
            pthread_mutex_init(global_ummutex_stat_mutex, NULL);
            global_ummutex_stat = [[NSMutableDictionary alloc]init];
            return 0;
        }
    }
    return 1;
}

void ummutex_stat_disable(void)
{
    global_ummutex_stat = NULL;
    pthread_mutex_destroy(global_ummutex_stat_mutex);
    free(global_ummutex_stat_mutex);
    global_ummutex_stat_mutex = NULL;
}

NSArray *ummutex_stat(BOOL sortByName)
{
    NSMutableArray *arr = [[NSMutableArray alloc]init];
    if(global_ummutex_stat==NULL)
    {
        return arr;
    }
    pthread_mutex_lock(global_ummutex_stat_mutex);
    NSArray *keys = [global_ummutex_stat allKeys];
    for(NSString *key in keys)
    {
        [arr addObject: [global_ummutex_stat[key] copy] ];
    }
    NSArray *arr2 = [arr sortedArrayUsingComparator: ^(UMMutexStat *a, UMMutexStat *b)
                     {
                         if(sortByName)
                         {
                             return [a.name compare:b.name];
                         }
                         else
                         {
                             if(a.lock_count == b.lock_count)
                             {
                                 return NSOrderedSame;
                             }
                             if(a.lock_count < b.lock_count)
                             {
                                 return NSOrderedDescending;
                             }
                             return NSOrderedAscending;
                         }
                     }];
    pthread_mutex_unlock(global_ummutex_stat_mutex);
    return arr2;
}

BOOL ummutex_stat_is_enabled(void)
{
    if(global_ummutex_stat_mutex==NULL)
    {
        return NO;
    }
    else
    {
        return YES;
    }
}
