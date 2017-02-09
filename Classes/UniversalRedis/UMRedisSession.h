//
//  UMRedisSession.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"
#import "UniversalSocket.h"

#define REDIS_PORT 6379

typedef enum RedisStatus
{
    REDIS_STATUS_OFF                        = 100,
    REDIS_STATUS_HAS_SOCKET                 = 101,
    REDIS_STATUS_MAJOR_FAILURE              = 102,
    REDIS_STATUS_MAJOR_FAILURE_RETRY_TIMER  = 103,
    REDIS_STATUS_CONNECTING                 = 104,
    REDIS_STATUS_CONNECTED                  = 105,     /* but not authenticated yet	*/
    REDIS_STATUS_ACTIVE                     = 106,  /* correctly logged in			*/
    REDIS_STATUS_CONNECT_RETRY_TIMER        = 107
} RedisStatus;

@interface UMRedisSession : UMObject
{
    UMSocket *socket;
    RedisStatus status;
    NSString *hostName;
    BOOL    autoReconnect;
}

@property (readwrite,strong) UMSocket *socket;
@property (readwrite,strong) NSString *hostName;
@property (readwrite,assign) RedisStatus status;

- (NSString *) redisStatusToString;

- (UMRedisSession *)initWithHost:(NSString *)hostName andPort:(long)port;
- (UMRedisSession *)initWithHost:(NSString *)hostName;
- (BOOL)reinitWithHost;
- (NSString *)description;

- (BOOL)connect;
- (BOOL)restart:(NSException *)socketException;
// We will try to restart once. If this does not success, return error,
- (BOOL)restart;
- (BOOL)stop;

/* thows NSException */
- (NSString *)ping;
- (NSString *) setObject:(NSData *)data forKey:(NSString *)key;
- (NSData *)getObjectForKey:(NSString *)key;
- (id)delObjectForKey:(id)key;
- (id)updateObject:(id)value forKey:(id)key;
- (id)getLike;
- (id)getLike:(NSString *)tableName withKey:(NSString *)key like:(NSString *)ymdh;
- (id)listDelForKey:(id)key andValue:(id)value;
- (id)listAddForKey:(id)key andValue:(id)value;

- (NSString *) hSetObject:(NSDictionary *)dict forKey:(NSString *)key;
- (NSMutableDictionary *)hGetAllObjectForKey:(NSString *)key;
- (NSString *) hincrFields:(NSArray *)arr ofKey:(NSString *)key by:(long)incr;
- (NSString *) hincrFields:(NSArray *)arr ofKey:(NSString *)key byFloat:(float)incr;
- (NSString *) hexistField:(NSString *)field ofKey:(NSString *)key;

- (NSString *) setJson:(NSDictionary *)dict forKey:(NSString *)key;
- (NSDictionary *)getJsonForKey:(NSString *)key;
- (id)updateJsonObject:(NSDictionary *)changedValues forKey:(id)key;
- (id)increaseJsonObject:(NSDictionary *)changedValues forKey:(id)key;

- (id)listLen:(id)key;
- (id)listGet:(id)key index:(int)i;
- (NSArray *)getListForKey:(id)key;
- (id)getKeys:(id)keypattern;
- (id)expireKey:(id)key inSeconds:(NSNumber *)sec;

@end
