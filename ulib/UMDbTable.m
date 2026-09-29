//
//  UMDbTable.m
//  ulibdb.framework
//
//  Created by Andreas Fink on 15.12.11.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMObject.h>
#import <ulib/ulib_config.h>
#import <ulib/UMDbTable.h>
#import <ulib/UMDbQueryType.h>
#import <ulib/UMDbQuery.h>
#import <ulib/UMDbSession.h>
#import <ulib/UMMySQLSession.h>
#import <ulib/UMAssert.h>
#import <ulib/NSString+ulib.h>

@implementation UMDbTable

@synthesize tableName;
@synthesize poolName;
@synthesize pools;
@synthesize autoCreate;

@synthesize tcAllQueries;
@synthesize tcSelects;
@synthesize tcInserts;
@synthesize tcUpdates;
@synthesize tcDeletes;
@synthesize tcGets;
@synthesize tcSets;
@synthesize tcRedisUpdates;
@synthesize tcDels;

@synthesize delayAllQueries;
@synthesize delaySelects;
@synthesize delayInserts;
@synthesize delayUpdates;
@synthesize delayDeletes;
@synthesize delayGets;
@synthesize delaySets;
@synthesize delayRedisUpdates;
@synthesize delayDels;


- (UMDbTable *)init
{
    return [self initWithConfig:NULL andPools:NULL];
}


- (UMDbTable *)initWithPool
{
    return [self initWithConfig:NULL andPools:NULL];
}

- (UMDbTable *)initWithConfig:(NSDictionary *)config
                     andPools:(UMSynchronizedDictionary *)newPools
{
    self=[super init];
    if(self)
    {
        self.autoCreate=YES;
        self.pools = newPools;
        if(config!=NULL)
        {
            if(config[@"enable"])
            {
                if([config[@"enable"] boolValue]==NO)
                {
                    return NULL;
                }
            }
            if(config[@"table-name"])
            {
                self.tableName = [config[@"table-name"] stringValue];
            }
            if(config[@"autocreate"])
            {
                self.autoCreate = [config[@"autocreate"] boolValue];
            }

            if(config[@"pool-name"])
            {
                self.poolName = [config[@"pool-name"] stringValue];
            }
        }
        tcAllQueries = [[UMThroughputCounter alloc]init];
        tcSelects = [[UMThroughputCounter alloc]init];
        tcInserts = [[UMThroughputCounter alloc]init];
        tcUpdates = [[UMThroughputCounter alloc]init];
        tcDeletes = [[UMThroughputCounter alloc]init];
    }
    return self;
}


- (void) addStatDelay:(double)delay query:(UMDbQueryType)type
{
    NSNumber *nr = @(delay);
    [delayAllQueries appendNumber:nr];
    switch(type)
    {
        case    UMDBQUERYTYPE_SELECT:
        case    UMDBQUERYTYPE_SELECT_BY_KEY:
            [delaySelects appendNumber:nr];
            break;
        case    UMDBQUERYTYPE_INSERT:
        case    UMDBQUERYTYPE_INSERT_BY_KEY:
        case    UMDBQUERYTYPE_INSERT_BY_KEY_TO_LIST:
            [delayInserts appendNumber:nr];
            break;
        case    UMDBQUERYTYPE_UPDATE:
        case    UMDBQUERYTYPE_UPDATE_BY_KEY:
        case    UMDBQUERYTYPE_INCREASE:
        case    UMDBQUERYTYPE_INCREASE_BY_KEY:
            [delayUpdates appendNumber:nr];
            break;
        case    UMDBQUERYTYPE_DELETE:
        case    UMDBQUERYTYPE_DELETE_BY_KEY:
            [delayDeletes appendNumber:nr];
            break;
        case    UMREDISTYPE_GET:
        case    UMREDISTYPE_HGET:
            [delayGets appendNumber:nr];
            break;
        case    UMREDISTYPE_SET:
        case    UMREDISTYPE_HSET:
            [delaySets appendNumber:nr];
            break;
        case    UMREDISTYPE_UPDATE:
            [delayRedisUpdates appendNumber:nr];
            break;
        case    UMREDISTYPE_DEL:
            [delayDels appendNumber:nr];
            break;
        default:
            break;
    }
}

- (void)increaseCountersForType:(UMDbQueryType)type
{
    [tcAllQueries increase];
    switch(type)
    {
        case    UMDBQUERYTYPE_SELECT:
        case    UMDBQUERYTYPE_SELECT_BY_KEY:
            [tcSelects increase];
            break;
        case    UMDBQUERYTYPE_INSERT:
        case    UMDBQUERYTYPE_INSERT_BY_KEY:
        case    UMDBQUERYTYPE_INSERT_BY_KEY_TO_LIST:
        [tcInserts increase];
            break;
        case    UMDBQUERYTYPE_UPDATE:
        case    UMDBQUERYTYPE_UPDATE_BY_KEY:
        case    UMDBQUERYTYPE_INCREASE:
        case UMDBQUERYTYPE_INCREASE_BY_KEY:
            [tcUpdates increase];
            break;
        case    UMDBQUERYTYPE_DELETE:
        case    UMDBQUERYTYPE_DELETE_BY_KEY:
            [tcDeletes increase];
            break;
        case    UMREDISTYPE_GET:
        case    UMREDISTYPE_HGET:
            [tcGets increase];
            break;
        case    UMREDISTYPE_SET:
        case    UMREDISTYPE_HSET:
            [tcSets increase];
            break;
        case    UMREDISTYPE_UPDATE:
            [tcRedisUpdates increase];
            break;
        case    UMREDISTYPE_DEL:
            [tcDels increase];
            break;
        default:
            break;
    }
}

- (UMDbPool *)pool
{
    if(_pool == NULL)
    {
        _pool = pools[poolName];
    }
    return _pool;
}

- (void)setPoolName:(NSString *)pn
{
    poolName = pn;
    
    _pool = NULL;
}

- (void)setPool:(UMDbPool *)pool
{
    _pool = pool;
}

- (NSString *)poolName
{
    return poolName;
}

- (void)autoCreate:(dbFieldDef *)fieldDef
           session:(UMDbSession *)session
{
    @autoreleasepool
    {
        if(autoCreate==YES)
        {
            NSArray *sqlCommands = [UMDbQuery createSql:tableName
                                             withDbType:[session.pool dbDriverType]
                                                session:session
                                       fieldsDefinition:fieldDef];
            [session queriesWithNoResult:sqlCommands allowFail:YES];
            if(_pool.dbDriverType==UMDBDRIVER_MYSQL)
            {
                UMMySQLSession *mySession =(UMMySQLSession *)session;
                NSDictionary *tableDef = [mySession explainTable:tableName];
                if(tableDef == NULL)
                {
                    NSLog(@"SQL: %@",sqlCommands);
                    NSLog(@"TableDefinition: %@",tableDef);
                    UMAssert(tableDef != NULL,@"Autocreation failed!");
                }
            }
        }
    }
}

@end
