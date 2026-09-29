//
//  UMDbRedisSession.h
//  ulibdb
//
//  Created by Andreas Fink on 23.01.14.
//
//

#import <ulib/UMDbSession.h>

#define REDIS_RETURN_EXISTS @":1"
#define REDIS_RETURN_FAILURE @":0"
#define REDIS_RETURN_EXCEPTION @":-1"
#define REDIS_RETURN_OK @"+OK"
#define REDIS_RETURN_INSERTED @":1"
#define REDIS_RETURN_UPDATED @":0"
#define REDIS_RETURN_PING_OK @"+PONG"


@class UMRedisSession, UMDbQuery, UMDbResult, UMLogHandler;

@interface UMDbRedisSession : UMDbSession
{
    UMRedisSession    *session;
    UMLogHandler	  *loghandler;
}

+(NSString *)updateByKeyForQuery:(UMDbQuery *)query params:(NSArray *)params primaryKeyValue:(id)primaryKeyValue;
+(NSString *)updateByKeyLikeForQuery:(UMDbQuery *)query params:(NSArray *)params primaryKeyValue:(id)primaryKeyValue;
+(NSString *)insertByKeyForQuery:(UMDbQuery *)query params:(NSArray *)params primaryKeyValue:(id)primaryKeyValue;
+(NSString *)selectByKeyForQuery:(UMDbQuery *)query params:(NSArray *)params primaryKeyValue:(id)primaryKeyValue;
+(NSString *)selectByKeyLikeForQuery:(UMDbQuery *)query params:(NSArray *)params primaryKeyValue:(id)primaryKeyValue;
+(NSString *)deleteByKeyForQuery:(UMDbQuery *)query params:(NSArray *)params primaryKeyValue:(id)primaryKeyValue;

@property(readwrite,strong)		UMLogHandler		*loghandler;
@property(readwrite,strong)		UMRedisSession      *session;

- (UMDbSession *)initWithPool:(UMDbPool *)pool;
- (void)dealloc;

- (BOOL)connect;
- (BOOL)reconnect;
- (void)disconnect;

- (BOOL)cachedQueryWithNoResult:(UMDbQuery *)query parameters:(NSArray *)params allowFail:(BOOL)failPermission primaryKeyValue:(id)primaryKeyValue;
- (BOOL)cachedQueryWithNoResult:(UMDbQuery *)query parameters:(NSArray *)params allowFail:(BOOL)failPermission;
- (BOOL)cachedQueryWithNoResult:(UMDbQuery *)query parameters:(NSArray *)params;
- (BOOL)cachedQueryWithNoResult:(UMDbQuery *)query;


- (UMDbResult *)cachedQueryWithMultipleRowsResult:(UMDbQuery *)query parameters:(NSArray *)params allowFail:(BOOL)failPermission primaryKeyValue:(id)primaryKeyValue;
- (UMDbResult *)cachedQueryWithMultipleRowsResult:(UMDbQuery *)query parameters:(NSArray *)params allowFail:(BOOL)failPermission;
- (UMDbResult *)cachedQueryWithMultipleRowsResult:(UMDbQuery *)query;

- (UMDbResult *)cachedQueryWithMultipleRowsResult:(UMDbQuery *)query parameters:(NSArray *)params;

// Return -1, when redis server is not reachable
- (int) hexistField:(NSString *)field ofKey:(NSString *)key allowFail:(BOOL)failPermission;
- (NSNumber *) hincrFields:(NSArray *)arr ofKey:(NSString *)key by:(NSNumber *)incr incrementIsInteger:(BOOL)flag allowFail:(BOOL)failPermission withId:(NSString *)qid;

- (int)errorCheck:(NSString  *)reply;
// Return nil on the case of error, including when the database cannot be reached. Ditto when
// there is no stat to be returned
- (NSMutableArray *)currentStat;
// Return YES, if delete was successfull, including case when there were nothing to delete
- (BOOL)deleteCurrent;

@end
