//
//  UMDbPool.h
//  ulibdb.framework
//
//  Created by Andreas Fink on 24.10.11.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.

#import <ulib/UMObject.h>
#import <ulib/UMDbQueryType.h>
#import <ulib/UMQueueSingle.h>
#import <ulib/UMDbDriverType.h>
#import <ulib/UMDbStorageType.h>
#import <ulib/UMThroughputCounter.h>
#import <ulib/UMAverageDelay.h>
#import <ulib/UMSleeper.h>
#import <ulib/UMMutex.h>

void umdbpool_out_of_sessions(void);
void umdbpool_null_session_returned(void);

typedef enum idle_status_T
{
    idleStatus_stopped,
    idleStatus_starting,
    idleStatus_running,
    idleStatus_terminating,
} idleStatus;


@class UMDbSession;
@class UMDbTable;

@interface UMDbPool : UMObject
{
    NSString        *version;
    NSString        *poolName;
    UMQueueSingle         *sessionsAvailable;
    UMQueueSingle         *sessionsDisconnected;
    UMQueueSingle         *sessionsInUse;

    NSString        *hostName;
    NSString        *hostAddr;
    int             port;
    NSString        *dbName;
    NSString        *user;
    NSString        *pass;
    NSString        *options;
    NSString        *socket;
    UMDbDriverType  dbDriverType;
    UMDbStorageType dbStorageType;
    int             minSessions;
    int             maxSessions;
    int             waitTimeout1;
    int             waitTimeout2;
    int             wait1count;
    int             wait2count;
 
    UMThroughputCounter   *tcAllQueries;
    UMThroughputCounter  *tcSelects;
    UMThroughputCounter  *tcInserts;
    UMThroughputCounter  *tcUpdates;
    UMThroughputCounter  *tcDeletes;
    UMThroughputCounter  *tcGets;
    UMThroughputCounter  *tcSets;
    UMThroughputCounter  *tcRedisUpdates;
    UMThroughputCounter  *tcDels;

    UMAverageDelay      *delayAllQueries;
    UMAverageDelay      *delaySelects;
    UMAverageDelay      *delayInserts;
    UMAverageDelay      *delayUpdates;
    UMAverageDelay      *delayDeletes;
    UMAverageDelay      *delayGets;
    UMAverageDelay      *delaySets;
    UMAverageDelay      *delayRedisUpdates;
    UMAverageDelay      *delayDels;

    idleStatus           idleTaskStatus;
    UMSleeper           *poolSleeper;
    UMMutex *_poolLock;
}

@property(readwrite,strong)    UMThroughputCounter   *tcAllQueries;
@property(readwrite,strong)    UMThroughputCounter  *tcSelects;
@property(readwrite,strong)    UMThroughputCounter  *tcInserts;
@property(readwrite,strong)    UMThroughputCounter  *tcUpdates;
@property(readwrite,strong)    UMThroughputCounter  *tcDeletes;
@property(readwrite,strong)    UMThroughputCounter  *tcGets;
@property(readwrite,strong)    UMThroughputCounter  *tcSets;
@property(readwrite,strong)    UMThroughputCounter  *tcRedisUpdates;
@property(readwrite,strong)    UMThroughputCounter  *tcDels;

@property(readwrite,strong)    UMAverageDelay      *delayAllQueries;
@property(readwrite,strong)    UMAverageDelay      *delaySelects;
@property(readwrite,strong)    UMAverageDelay      *delayInserts;
@property(readwrite,strong)    UMAverageDelay      *delayUpdates;
@property(readwrite,strong)    UMAverageDelay      *delayDeletes;
@property(readwrite,strong)    UMAverageDelay      *delayGets;
@property(readwrite,strong)    UMAverageDelay      *delaySets;
@property(readwrite,strong)    UMAverageDelay      *delayRedisUpdates;
@property(readwrite,strong)    UMAverageDelay      *delayDels;

@property(readwrite,strong)     NSString        *version;
@property(readwrite,strong)     NSString        *poolName;
@property(readwrite,strong)     NSString        *hostName;
@property(readwrite,strong)     NSString        *hostAddr;
@property(readwrite,assign)     int             port;
@property(readwrite,assign)     int             minSessions;
@property(readwrite,assign)     int             maxSessions;
@property(readwrite,assign)     int             waitTimeout1;
@property(readwrite,assign)     int             waitTimeout2;
@property(readwrite,assign)     int             wait1count;
@property(readwrite,assign)     int             wait2count;
@property(readwrite,strong)     NSString        *dbName;
@property(readwrite,strong)     NSString        *user;
@property(readwrite,strong)     NSString        *pass;
@property(readwrite,strong)     NSString        *options;
@property(readwrite,strong)     NSString        *socket;
@property(readwrite,assign)     UMDbDriverType  dbDriverType;
@property(readwrite,assign)     UMDbStorageType dbStorageType;
@property(readwrite,strong)     UMSleeper       *poolSleeper;

- (NSUInteger)sessionsAvailableCount;
- (NSUInteger)sessionsInUseCount;
- (NSUInteger)sessionsDisconnectedCount;

- (UMDbPool *) init;
- (UMDbPool *)initWithConfig:(NSDictionary *)config;
- (UMDbPool *)initWithConfig:(NSDictionary *)config logFeed:(UMLogFeed *)logFeed;
- (void)dealloc;

- (UMDbSession *)newSession;
- (UMDbSession *)grabSession:(const char *)file line:(int)line func:(const char *)func;
- (void) returnSession:(UMDbSession *)session file:(const char *)file line:(long)line func:(const char *)func;

- (void) timeoutWaitingForSessions;
- (void) startSessions;
- (void) stopSessions;
- (void) removeSessions;
- (void) pingAllUnusedSessions;
- (void) pingAllDisconnectedSessions;
- (void) removeDisconnectedSessions;
- (void) addConnectedSessions;

- (void) startIdler;
- (void) stopIdler;
- (void) idleTask;
- (void) idler:(id)unused;

- (NSUInteger)inUseSessionsCount;
- (NSUInteger)availableSessionsCount;
- (NSUInteger)disconnectedSessionsCount;
- (double) queriesPerSec:(int)timespan;
- (double) selectQueriesPerSec:(int)timespan;
- (double) insertQueriesPerSec:(int)timespan;
- (double) updateQueriesPerSec:(int)timespan;
- (double) deleteQueriesPerSec:(int)timespan;
- (void)increaseCountersForType:(UMDbQueryType)type table:(UMDbTable *)table;
- (void) addStatDelay:(double)delay query:(UMDbQueryType)type table:(UMDbTable *)table;

@end
