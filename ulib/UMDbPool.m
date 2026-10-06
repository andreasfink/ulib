//
//  UMDbPool.m
//  ulibdb.framework
//
//  Created by Andreas Fink on 24.10.11.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.

#import <ulib/UMObject.h>
#import <ulib/NSString+ulib.h>
#import <ulib/NSMutableString+ulib.h>
#import <ulib/NSData+ulib.h>
#import <ulib/NSMutableData+ulib.h>
#import <ulib/UMAssert.h>
#import <ulib/UMLogFeed.h>
#import <ulib/UMThreadHelpers.h>

#import <ulib/ulib_config.h>
#import <ulib/UMDbSession.h>
#import <ulib/UMDbPool.h>
#import <ulib/UMMySQLSession.h>
#import <ulib/UMPgSQLSession.h>
#import <ulib/UMSqLiteSession.h>
#import <ulib/UMDbRedisSession.h>
#import <ulib/UMDbQueryType.h>
#import <ulib/UMDbTable.h>

#include <stdlib.h>
#include <unistd.h>
//#define	POOL_DEBUG 1

void umdbpool_out_of_sessions(void)
{
    /* break in debugger on this function:  break set -b umdbpool_out_of_sessions */
    //NSLog(@"We run out of sessions, connecting new one");
    
}

void umdbpool_null_session_returned(void)
{
    /* break in debugger on this function:  break set -b umdbpool_out_of_sessions */
    NSLog(@"We return NULL as session");
    
}


@implementation UMDbPool

- (UMDbPool *) init
{
    return [self initWithConfig:NULL logFeed:NULL];
}

- (NSUInteger)sessionsAvailableCount
{
    return [_sessionsAvailable count];
}

- (NSUInteger)sessionsInUseCount
{
    return [_sessionsInUse count];
}

- (NSUInteger)sessionsDisconnectedCount
{
    return [_sessionsDisconnected count];
}


- (UMDbPool *)initWithConfig:(NSDictionary *)config
{
    return [self initWithConfig:config logFeed:NULL];
}

- (UMDbPool *)initWithConfig:(NSDictionary *)config logFeed:(UMLogFeed *)logFeed
{
    self=[super init];
    if(self)
    {
        _logFeed = logFeed;
        _sessionsAvailable       = [[UMQueueSingle alloc]init];
        _sessionsInUse           = [[UMQueueSingle alloc]init];
        _sessionsDisconnected    = [[UMQueueSingle alloc]init];
        _waitTimeout1            = 2;
        _idleTaskStatus          = idleStatus_stopped;
        _poolLock = [[UMMutex alloc]initWithName:@"db-pool-lock"];

        _tcAllQueries = [[UMThroughputCounter alloc]init];
        _tcSelects = [[UMThroughputCounter alloc]init];
        _tcInserts = [[UMThroughputCounter alloc]init];
        _tcUpdates = [[UMThroughputCounter alloc]init];
        _tcDeletes = [[UMThroughputCounter alloc]init];
        _tcGets    = [[UMThroughputCounter alloc]init];
        _tcSets    = [[UMThroughputCounter alloc]init];
        _tcRedisUpdates = [[UMThroughputCounter alloc]init];
        _tcDels = [[UMThroughputCounter alloc]init];
        
        _delayAllQueries = [[UMAverageDelay alloc]init];
        _delaySelects = [[UMAverageDelay alloc]init];
        _delayInserts = [[UMAverageDelay alloc]init];
        _delayUpdates = [[UMAverageDelay alloc]init];
        _delayDeletes = [[UMAverageDelay alloc]init];
        _delayGets = [[UMAverageDelay alloc]init];
        _delaySets = [[UMAverageDelay alloc]init];
        _delayRedisUpdates = [[UMAverageDelay alloc]init];
        _delayDels = [[UMAverageDelay alloc]init];
        _poolSleeper =[[UMSleeper alloc]initFromFile:__FILE__ line:__LINE__ function:__func__];
        [_poolSleeper prepare];
        _waitTimeout2 = 30;
        _waitTimeout1 = 3;
        _minSessions = 3;
        _maxSessions = 20;

        if(config!=NULL)
        {
            if(config[@"enable"]!= NULL)
            {
                if([config[@"enable"] boolValue]==NO)
                {
                    return NULL;
                }
            }
#define SET_STRING(config,var,name) \
            if(config[name]) \
            { \
                id val = config[name]; \
                if([val isKindOfClass:[NSString class]]) \
                { \
                    var = val; \
                } \
                else \
                { \
                    var = [val stringValue]; \
                } \
            }
#define SET_INTEGER(config,var,name) \
            if(config[name]) \
            { \
                id val = config[name]; \
                if([val isKindOfClass:[NSString class]]) \
                { \
                    var = (int)[val integerValue]; \
                } \
                if([val isKindOfClass:[NSNumber class]]) \
                { \
                    var = (int)[val integerValue]; \
                } \
            }

            SET_STRING(config,_version,@"version");
            SET_STRING(config,_poolName,@"name");
            SET_STRING(config,_hostName,@"host");
            SET_STRING(config,_dbName,@"database-name");
            
            NSString *driverTypeString;
            SET_STRING(config,driverTypeString,@"driver");
            
            if([driverTypeString caseInsensitiveCompare:@"mysql"]==NSOrderedSame)
            {
                _dbDriverType = UMDBDRIVER_MYSQL;
            }
            else  if([driverTypeString caseInsensitiveCompare:@"pgsql"]==NSOrderedSame)
            {
                _dbDriverType = UMDBDRIVER_PGSQL;
            }
            else  if([driverTypeString caseInsensitiveCompare:@"sqlite"]==NSOrderedSame)
            {
                _dbDriverType = UMDBDRIVER_SQLITE;
            }
            else  if([driverTypeString caseInsensitiveCompare:@"redis"]==NSOrderedSame)
            {
                _dbDriverType = UMDBDRIVER_REDIS;
            }
            else  if([driverTypeString caseInsensitiveCompare:@"file"]==NSOrderedSame)
            {
                _dbDriverType = UMDBDRIVER_FILE;
            }
            else
            {
                UMAssert(0,@"Unknown driver type %@",driverTypeString);
            }
                        
            NSString *storageTypeString;
            SET_STRING(config,storageTypeString,@"storage-type");
            if([storageTypeString isEqualToString:@"json"])
            {
                _dbStorageType = UMDBSTORAGE_JSON;
            }
            else  if([storageTypeString isEqualToString:@"hash"])
            {
                _dbStorageType = UMDBSTORAGE_HASH;
            }
            else
            {
                _dbStorageType = UMDBSTORAGE_JSON;
            }
            
            SET_STRING(config,_user,@"user");
            SET_STRING(config,_pass,@"pass");
            SET_INTEGER(config,_port,@"port");
            SET_INTEGER(config,_minSessions,@"min-sessions");
            SET_INTEGER(config,_maxSessions,@"max-sessions");
            SET_STRING(config,_socket,@"socket");

            NSString *pingString;
            
            SET_STRING(config,pingString,@"ping-interval");
            if([pingString length]>0)
            {
                _waitTimeout2 = (int)[pingString integerValue];
                if(self.waitTimeout2 < 15)
                {
                    _waitTimeout2 = 15;
                }
            }
            else
            {
                _waitTimeout2 = 30;
            }
            [self startSessions];
            [self startIdler];
        }
    }
    return self;
}

- (void)dealloc
{
    _dbDriverType = UMDBDRIVER_NULL;
    [self stopIdler];
    _poolSleeper = NULL;
}

- (void)startIdler
{
    if(_idleTaskStatus == idleStatus_stopped)
    {
        _idleTaskStatus = idleStatus_starting;
        [self performSelectorInBackground:@selector(idler:) withObject:self];
        int i=0;
        while((_idleTaskStatus != idleStatus_running) && (i++ <2000))
        {
            usleep(1000);
        }
        if(i>=2000)
        {
            _idleTaskStatus = idleStatus_stopped;
        }
    }
}


- (void)stopIdler
{
    if(_idleTaskStatus != idleStatus_stopped)
    {
        _idleTaskStatus = idleStatus_terminating;
        int i = 0;
        [_poolSleeper wakeUp];
        while ((_idleTaskStatus != idleStatus_stopped) && (i++ <2000))
        {
            usleep(1000);
        }
        _idleTaskStatus = idleStatus_stopped;
    }
}


- (void)idler:(id)unused
{
    NSString *s = [NSString stringWithFormat:@"dbpool-idler(%@)",self.poolName];
    ulib_set_thread_name(s);

    @autoreleasepool
    {
        NSString *msg = [NSString stringWithFormat:@"starting idle task for database pool %@", _poolName];
        [self.logFeed info:0 inSubsection:@"database" withText:msg];
        _idleTaskStatus = idleStatus_running;
        
        while(_idleTaskStatus==idleStatus_running)
        {
            UMSleeper_Signal ret = [_poolSleeper sleep:(1000000 * self.waitTimeout2)];
            if(ret == 0)
            {
                [self idleTask];
            }
            if(ret == UMSleeper_Error)
            {
                break;
            }
        }
        msg = [NSString stringWithFormat:@"terminating idle task for database pool %@", _poolName];
        [self.logFeed info:0 inSubsection:@"database" withText:msg];
        _idleTaskStatus = idleStatus_stopped;
    }
}

- (void) idleTask
{
    ummutex_lock(_poolLock);
    [self addConnectedSessions];
    [self removeDisconnectedSessions];
    [self pingAllUnusedSessions];
    [self pingAllDisconnectedSessions];
    ummutex_unlock(_poolLock);
}

// Move connected sessions to list of available sessions

- (void) addConnectedSessions
{
    ummutex_lock(_poolLock);
    @try
    {
        UMDbSession *result = nil;
        BOOL isConnected = NO;
        
        long len = [_sessionsDisconnected count];
        while(len--)
        {
            result = [_sessionsDisconnected getFirst];
            isConnected = [result isConnected];
            if (isConnected)
            {
                [_sessionsInUse append:result];
            }
            else
            {
                [_sessionsDisconnected append:result];
            }
        }
    }
    @finally
    {
        ummutex_unlock(_poolLock);
    }
 }

// Drop disconnected sessions from available connections
- (void) removeDisconnectedSessions
{
    ummutex_lock(_poolLock);
    @try
    {
        UMDbSession *result = nil;
        BOOL isConnected = NO;
        
        long len = [_sessionsAvailable count];
        
        while (len--)
        {
            result = [_sessionsAvailable getFirst];
            if(result)
            {
                isConnected = [result isConnected];
                if (!isConnected)
                {
                    [_sessionsDisconnected append:result];
                }
                else
                {
                    [_sessionsAvailable append:result];
                }
            }
        }
    }
    @finally
    {
        ummutex_unlock(_poolLock);
    }
}

// Ping all unused sessions and mark discoonected, if ping did not work
- (void) pingAllUnusedSessions
{
    ummutex_lock(_poolLock);
    @try
    {
        UMDbSession *s = nil;

        long len = [_sessionsAvailable count];
        while (len-- > 0)
        {
            s = [_sessionsAvailable getFirst];
            BOOL success = [s ping];
            if (!success)
            {
                [_sessionsDisconnected append:s];
            }
            else
            {
                [_sessionsAvailable append:s];
            }
        }
    }
    @finally
    {
        ummutex_unlock(_poolLock);
    }
}

/* Return disconnect session to available pool, if ping successes and if there are no queries to redone.
 * Session returns into available pool only when all required resends are done.*/
- (void) pingAllDisconnectedSessions
{
    ummutex_lock(_poolLock);
    @try
    {
        
        UMDbSession *s = nil;
        long len = [_sessionsDisconnected count];
        
        while (len-- > 0)
        {
            s = [_sessionsDisconnected getFirst];
            BOOL success = [s ping];
            if (success)
            {
                [_sessionsAvailable append:s];
            }
            else
            {
                [_sessionsDisconnected append:s];
            }
        }
    }
    @finally
    {
        ummutex_unlock(_poolLock);
    }
}


- (UMDbSession *)newSession
{
    ummutex_lock(_poolLock);
    @try
    {
        UMDbSession *session = NULL;
        switch (_dbDriverType)
        {
#ifdef HAVE_MYSQL
            case UMDBDRIVER_MYSQL:
                session = (UMDbSession *)[[UMMySQLSession alloc]initWithPool:self];
                break;
#endif
#ifdef HAVE_PGSQL
            case UMDBDRIVER_PGSQL:
                session = (UMDbSession *)[[UMPgSQLSession alloc]initWithPool:self];
                break;
#endif
#ifdef HAVE_SQLITE
            case UMDBDRIVER_SQLITE:
                session = (UMDbSession *)[[UMSqLiteSession alloc]initWithPool:self];
                break;
#endif
            case UMDBDRIVER_REDIS:
                session = (UMDbSession *)[[UMDbRedisSession alloc]initWithPool:self];
                break;
            default:
                session = [[UMDbSession alloc]initWithPool:self];
                break;
        }
        NSAssert(session.pool==self,@"New session without proper assigned pool");
        session.pool = self;
        [session connect];
        return session;
    }
    @finally
    {
        ummutex_unlock(_poolLock);
    }
}

- (UMDbSession *)grabSession:(const char *)file line:(int)line func:(const char *)func
{
#ifdef POOL_DEBUG
    NSLog(@"UMDbPool grabSession called from %s:%ld %s()",file,line,func);
#endif
    UMDbSession *result = NULL;
    time_t   start;
    time_t   now;
    BOOL wait1hit = NO;
    bool wait2hit = NO;

    time(&now);
    start = now;
    
    BOOL endNow=NO;
    BOOL noSessionAvailable=NO;
    while(endNow==NO)
    {
        noSessionAvailable=NO;

        ummutex_lock(_poolLock);
        if(self.sessionsAvailableCount>0)
        {
            result = [_sessionsAvailable getFirst];
            [_sessionsInUse append:result];
            endNow = YES;
        }
        else
        {
            umdbpool_out_of_sessions();
            if(self.sessionsInUseCount < self.maxSessions)
            {
                result = [self newSession];
                if(result)
                {
                    NSAssert(result.pool==self,@"Ouch session without proper assigned pool");
                    [_sessionsInUse append:result];
                    endNow = YES;
                }
            }
            else
            {
                noSessionAvailable=YES;
            }
        }
        ummutex_unlock(_poolLock);

        
        if(noSessionAvailable)
        {
            time(&now);
            /* waitTimeout2 is abslute timeout */
            if( (now - start) > _waitTimeout2)
            {
                wait2hit=YES;
                endNow = YES;
            }
            else
            {
                UMSleeper   *sleeper = [[UMSleeper alloc]initFromFile:__FILE__ line:__LINE__ function:__func__];
                [sleeper prepare];
                if((now - start) <= _waitTimeout1)
                {
                    long long msdelay = random() % 50000 + 100000;/* sleep something like 100ms */
                    UMSleeper_Signal ret = [sleeper sleep:msdelay];
                    if(ret == UMSleeper_Error)
                    {
                        /**/;
                    }
                }
                else
                {
                    long long msdelay = random() % 100000 + 500000; /* sleep something like 0.5s */
                    UMSleeper_Signal ret = [sleeper sleep:msdelay];
                    if(ret == UMSleeper_Error)
                    {
                        /**/;
                    }
                    wait1hit=YES;
                }
                sleeper = NULL;
            }
        }
    }
    
    if(result==NULL)
    {
        [self timeoutWaitingForSessions];
        if(wait2hit)
        {
            _wait2count++;
        }
        else if(wait1hit)
        {
            _wait1count++;
        }
        umdbpool_null_session_returned();
    }
    else
    {
        UMAssert([result.pool isEqualTo:self]==YES,@"got an entry from another pool %@. Last used at %@:%ld" ,
                 result.pool.poolName,
                 result.lastUsedFile,
                 result.lastUsedLine);

        [result touchGrabTimer];
        [result setUsedFrom:file line:line func:func];
    }
    return result;
}

- (void)timeoutWaitingForSessions;
{
    NSLog(@"Timeout waiting for DB sessions");
}

- (void)returnSession:(UMDbSession *)session file:(const char *)file line:(long)line func:(const char *)func
{
#ifdef POOL_DEBUG
    NSLog(@"UMDbPool returnSession called from %s:%ld %s()",file,line,func);
#endif

    if(session)
    {
        ummutex_lock(_poolLock);
        [_sessionsInUse removeObject:session];
        [session setUsedFrom:file line:line func:func];
        [_sessionsAvailable append:session];
        ummutex_unlock(_poolLock);

    }
    else
    {
        NSLog(@"We can't return a NULL session");
    }
}


/* Do both disconnected and in use sessions, because this could called before session is marked disconnected*/

- (void)returnSession:(UMDbSession *)session
{
    return [self returnSession:session file:__FILE__ line:__LINE__ func:__func__];
}

- (void) startSessions
{
    ummutex_lock(_poolLock);
    for (int i=0;i<_minSessions;i++)
    {
        UMDbSession *session = [self newSession];
        session.logFeed = _logFeed;
        [_sessionsAvailable append:session];
    }
    ummutex_unlock(_poolLock);
}

- (void) stopSessions
{
    ummutex_lock(_poolLock);
    UMDbSession *session = [_sessionsInUse getFirst];
    while(session)
    {
        [session disconnect];
        session = [_sessionsInUse getFirst];
    }

    session = [_sessionsAvailable getFirst];
    while(session)
    {
        [session disconnect];
        session = [_sessionsAvailable getFirst];
    }
    ummutex_unlock(_poolLock);
}

- (void) removeSessions
{
    _sessionsInUse = [[UMQueueSingle alloc]init];
    _sessionsAvailable = [[UMQueueSingle alloc]init];
}


- (NSUInteger)inUseSessionsCount
{
    return [_sessionsInUse count];
}

- (NSUInteger)availableSessionsCount
{
    return  [_sessionsAvailable count];
}

- (NSUInteger)disconnectedSessionsCount
{
    return [_sessionsDisconnected count];
}


- (double) queriesPerSec:(int)timespan
{
    return [_tcAllQueries getSpeedForSeconds:timespan];
}

- (double) selectQueriesPerSec:(int)timespan
{
    return [_tcSelects getSpeedForSeconds:timespan];
}

- (double) insertQueriesPerSec:(int)timespan
{
    return [_tcInserts getSpeedForSeconds:timespan];
}

- (double) updateQueriesPerSec:(int)timespan
{
    return [_tcUpdates getSpeedForSeconds:timespan];
}

- (double) deleteQueriesPerSec:(int)timespan
{
    return [_tcDeletes getSpeedForSeconds:timespan];
}

- (void) addStatDelay:(double)delay query:(UMDbQueryType)type table:(UMDbTable *)table
{
    NSNumber *nr = @(delay);
    [_delayAllQueries appendNumber:nr];
    switch(type)
    {
        case    UMDBQUERYTYPE_SELECT:
        case    UMDBQUERYTYPE_SELECT_BY_KEY:
        case    UMDBQUERYTYPE_SELECT_BY_KEY_LIKE:
        case    UMDBQUERYTYPE_SELECT_BY_KEY_FROM_LIST:
        case    UMDBQUERYTYPE_SELECT_LIST_BY_KEY_LIKE:
            [_delaySelects appendNumber:nr];
            break;
        case    UMDBQUERYTYPE_INSERT:
        case    UMDBQUERYTYPE_INSERT_BY_KEY:
        case    UMDBQUERYTYPE_INSERT_BY_KEY_TO_LIST:
            [_delayInserts appendNumber:nr];
            break;
        case    UMDBQUERYTYPE_UPDATE:
        case    UMDBQUERYTYPE_UPDATE_BY_KEY:
        case    UMDBQUERYTYPE_INCREASE:
        case    UMDBQUERYTYPE_INCREASE_BY_KEY:
            [_delayUpdates appendNumber:nr];
            break;
        case    UMDBQUERYTYPE_DELETE:
        case    UMDBQUERYTYPE_DELETE_BY_KEY:
        case    UMDBQUERYTYPE_DELETE_IN_LIST_BY_KEY_AND_VALUE:
        case    UMDBQUERYTYPE_EXPIRE_KEY:
            [_delayDeletes appendNumber:nr];
            break;
        case    UMREDISTYPE_GET:
        case    UMREDISTYPE_HGET:
            [_delayGets appendNumber:nr];
            break;
        case    UMREDISTYPE_SET:
        case    UMREDISTYPE_HSET:
            [_delaySets appendNumber:nr];
            break;
        case    UMREDISTYPE_UPDATE:
            [_delayRedisUpdates appendNumber:nr];
            break;
        case    UMREDISTYPE_DEL:
            [_delayDels appendNumber:nr];
            break;
        default:
            break;
    }
    if (table)
    {
        [table addStatDelay:delay query:type];
    }
   
}

- (void)increaseCountersForType:(UMDbQueryType)type table:(UMDbTable *)table
{
    [_tcAllQueries increase];
    switch(type)
    {
        case    UMDBQUERYTYPE_SELECT:
        case    UMDBQUERYTYPE_SELECT_BY_KEY:
            [_tcSelects increase];
            break;
        case    UMDBQUERYTYPE_INSERT:
        case    UMDBQUERYTYPE_INSERT_BY_KEY:
        case    UMDBQUERYTYPE_INSERT_BY_KEY_TO_LIST:
            [_tcInserts increase];
            break;
        case    UMDBQUERYTYPE_UPDATE:
        case    UMDBQUERYTYPE_UPDATE_BY_KEY:
        case    UMDBQUERYTYPE_INCREASE:
        case    UMDBQUERYTYPE_INCREASE_BY_KEY:
            [_tcUpdates increase];
            break;
        case    UMDBQUERYTYPE_DELETE:
        case    UMDBQUERYTYPE_DELETE_BY_KEY:
        case    UMDBQUERYTYPE_DELETE_IN_LIST_BY_KEY_AND_VALUE:
        case    UMDBQUERYTYPE_EXPIRE_KEY:
            [_tcDeletes increase];
            break;
        case    UMREDISTYPE_GET:
        case    UMREDISTYPE_HGET:
            [_tcGets increase];
            break;
        case    UMREDISTYPE_SET:
        case    UMREDISTYPE_HSET:
            [_tcSets increase];
            break;
        case    UMREDISTYPE_UPDATE:
            [_tcRedisUpdates increase];
            break;
        case    UMREDISTYPE_DEL:
            [_tcDels increase];
            break;
        default:
            break;
    }
    if (table)
    {
        [table increaseCountersForType:type];
    }
}

- (NSString *)description
{
    NSMutableString *s = [NSMutableString stringWithString:[super description]];
    if (_version)
    {
        [s appendFormat:@"server version for redis hash: %@\n",_version];
    }
    [s appendFormat:@"PoolName: %@\n",_poolName];
    [s appendFormat:@" dbName: %@\n",_dbName];
    [s appendFormat:@" host: %@\n",_hostName];
    [s appendFormat:@" addr: %@\n",_hostAddr];
    [s appendFormat:@" port: %d\n",_port];
    [s appendFormat:@" minSessions: %d\n",_minSessions];
    [s appendFormat:@" maxSessions: %d\n",_maxSessions];
    [s appendFormat:@" waitTimeout1: %d\n",_waitTimeout1];
    [s appendFormat:@" waitTimeout2: %d\n",_waitTimeout2];
    [s appendFormat:@" options: %@\n",_options];
    [s appendFormat:@" socket: %@\n",_socket];
    [s appendFormat:@" driverType: %s\n",dbdrivertype_to_string(_dbDriverType)];
    [s appendFormat:@" storageType: %s\n",dbstoragetype_to_string(_dbStorageType)];
    
    if(_sessionsAvailable)
    {
        [s appendFormat:@" sessionsAvailable: %d items\n",(int)[_sessionsAvailable count]];
    }
    else
    {
        [s appendFormat:@" sessionsAvailable: NULL\n"];
    }
    
    if(_sessionsInUse)
    {
        [s appendFormat:@" sessionsInUse: %d items\n",(int)[_sessionsInUse count]];
    }
    else
    {
        [s appendFormat:@" sessionsInUse: NULL\n"];
    }
    
    if(_sessionsDisconnected)
    {
        [s appendFormat:@" sessionsDisconnected: %d items\n",(int)[_sessionsDisconnected count]];
    }
    else
    {
        [s appendFormat:@" sessionsDisconnected: NULL\n"];
    }
    return s;
}

- (NSString *)inUseDescription
{
    NSMutableString *s = [NSMutableString stringWithString:[super description]];
    ummutex_lock(_poolLock);
    UMDbSession *session = [_sessionsInUse getFirst];
    while(session)
    {
        [s appendFormat:@"%@\n",[session inUseDescription]];
        [_sessionsInUse append:session];
    }
    ummutex_unlock(_poolLock);
    return s;
}
@end
