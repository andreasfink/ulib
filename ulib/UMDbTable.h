//
//  UMDbTable.h
//  ulibdb.framework
//
//  Created by Andreas Fink on 15.12.11.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMObject.h>
#import <ulib/UMDbQueryType.h>
#import <ulib/UMDbFieldDefinitions.h>
#import <ulib/UMDbPool.h>
#import <ulib/UMSynchronizedDictionary.h>

#define FLF  __FILE__ line:__LINE__ func:__func__
@class UMDbSession;

@interface UMDbTable : UMObject
{
    NSString *tableName;
    NSString *poolName;
 
    UMThroughputCounter  *tcAllQueries;
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

    BOOL autoCreate;
    UMSynchronizedDictionary *pools;
    UMDbPool *_pool;
}

@property(readwrite,strong) NSString *tableName;
@property(readwrite,strong) NSString *poolName;
@property(readwrite,strong) UMSynchronizedDictionary *pools;
@property(readwrite,assign) BOOL autoCreate;

- (void)increaseCountersForType:(UMDbQueryType)type;
- (void) addStatDelay:(double)delay query:(UMDbQueryType)type;

- (UMDbTable *)initWithConfig:(NSDictionary *)config andPools:(UMSynchronizedDictionary *)pools;

- (void)autoCreate:(dbFieldDef *)fieldDef
           session:(UMDbSession *)session;

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


@property(readwrite,strong)    UMDbPool *pool;

@end
