//
//  UMDbRedisSession.m
//  ulibdb
//
//  Created by Andreas Fink on 23.01.14.
//
//

#import "UMDbRedisSession.h"
#import <ulib/ulib.h>
#import "UMDbStorageType.h"
#import "UMDbFieldDefinitions.h"
#import "UMDbFileSession.h"
#import "UMDbQueryType.h"
#import "UMDbPool.h"
#import "UMDbQuery.h"
#import "UMDbResult.h"
#import <ulib/ulib_config.h>

@implementation UMDbRedisSession

@synthesize loghandler;
@synthesize session;

/* we share the same query string syntax as the file session driver 
   so we just use its encoding method */

+(NSString *)updateByKeyForQuery:(UMDbQuery *)query  params:(NSArray *)params primaryKeyValue:(id)primaryKeyValue
{
    return [UMDbFileSession updateByKeyForQuery:query params:params primaryKeyValue:primaryKeyValue];
}

+(NSString *)updateByKeyLikeForQuery:(UMDbQuery *)query  params:(NSArray *)params primaryKeyValue:(id)primaryKeyValue
{
    return [UMDbFileSession updateByKeyLikeForQuery:query params:params primaryKeyValue:primaryKeyValue];
}

+(NSString *)insertByKeyForQuery:(UMDbQuery *)query  params:(NSArray *)params primaryKeyValue:(id)primaryKeyValue
{
    return [UMDbFileSession insertByKeyForQuery:query params:params primaryKeyValue:primaryKeyValue];
    
}
+(NSString *)selectByKeyForQuery:(UMDbQuery *)query  params:(NSArray *)params primaryKeyValue:(id)primaryKeyValue
{
    return [UMDbFileSession selectByKeyForQuery:query params:params primaryKeyValue:primaryKeyValue];
}

+(NSString *)selectByKeyLikeForQuery:(UMDbQuery *)query  params:(NSArray *)params primaryKeyValue:(id)primaryKeyValue
{
    return [UMDbFileSession selectByKeyLikeForQuery:query params:params primaryKeyValue:primaryKeyValue];
}

+(NSString *)deleteByKeyForQuery:(UMDbQuery *)query  params:(NSArray *)params primaryKeyValue:(id)primaryKeyValue
{
    return [UMDbFileSession deleteByKeyForQuery:query params:params primaryKeyValue:primaryKeyValue];
}

+(NSString *)deleteByKeyAndValueForQuery:(UMDbQuery *)query params:(NSArray *)params primaryKeyValue:(id)primaryKeyValue
{
    return [UMDbFileSession deleteByKeyAndValueForQuery:query params:params primaryKeyValue:primaryKeyValue];
}


- (UMDbRedisSession *)initWithPool:(UMDbPool *)p
{
    if (!p)
    {
        return nil;
    }
    self = [super initWithPool:p];
    if(self)
    {
        session = [[UMRedisSession alloc] initWithHost:[pool hostName] andPort:0];
    }
    return self;
}


- (void)dealloc
{
    [self.logFeed info:0 withText:[NSString stringWithFormat:@"UMMySQLConnection '%@'is being deallocated\n",name]];
    
    name = nil;
}


- (BOOL)connect
{
    BOOL connected = [session connect];
    if(!connected)
    {
        NSMutableString *reason = [NSMutableString stringWithString:@"Cannot connect to redis server"];
        [self.logFeed majorError:0 inSubsection:@"redis" withText:reason];
        return NO;
    }
    
    sessionStatus = UMDBSESSION_STATUS_CONNECTED;
    return YES;
}

- (BOOL)reconnect
{
    BOOL connected = [session restart];
    if(!connected)
    {
        NSMutableString *reason = [NSMutableString stringWithString:@"Cannot reconnect to redis server"];
        [self.logFeed majorError:0 inSubsection:@"redis" withText:reason];
        return NO;
    }
    
    sessionStatus = UMDBSESSION_STATUS_CONNECTED;
    return YES;
}


- (void) disconnect
{
    if(sessionStatus == UMDBSESSION_STATUS_CONNECTED)
    {
        sessionStatus = UMDBSESSION_STATUS_DISCONNECTED;
        [session stop];
    }
}

- (BOOL)cachedQueryWithNoResult:(UMDbQuery *)query parameters:(NSArray *)params allowFail:(BOOL)failPermission
{
    return [self cachedQueryWithNoResult:query parameters:params allowFail:failPermission primaryKeyValue:NULL];
}

- (BOOL)cachedQueryWithNoResult:(UMDbQuery *)query parameters:(NSArray *)params allowFail:(BOOL)failPermission primaryKeyValue:(id)primaryKeyValue
{
    long long start = [UMUtil milisecondClock];

    NSString *key = [query keyForParameters:params];

    if(query.type==UMDBQUERYTYPE_INSERT_BY_KEY_TO_LIST)
    {
        if((params.count != 1) || (primaryKeyValue == NULL) || (query.primaryKeyName == NULL))
        {
            @throw([NSException exceptionWithName:@"INSERT_BY_KEY_TO_LIST requires exactly one param and a key name and key value"
                                           reason:NULL
                                         userInfo:@{
                                                    @"sysmsg" : @"INSERT_BY_KEY_TO_LIST requires exactly one param and a key name and key value",
                                                    @"func": @(__func__),
                                                    @"err": @(-1)
                                                    }]);

        }
        UMJsonWriter *writer = [[UMJsonWriter alloc]init];
        NSString *jsonString = [writer stringWithObject:@{query.primaryKeyName: primaryKeyValue, query.fields [0]:params[0]}];
        [session listAddForKey:key andValue:jsonString];
    }
    else if(query.type==UMDBQUERYTYPE_INSERT_BY_KEY)
    {
        NSMutableDictionary *insertDict = [[NSMutableDictionary alloc]init];
        NSUInteger i;
        NSUInteger n = query.fields.count;
        for(i=0;i<n;i++)
        {
            insertDict[query.fields[i]]=params[i] ? params[i] : [NSNull null] ;
        }
        
        if (query.table.pool.dbStorageType == UMDBSTORAGE_HASH)
        {
            [session hSetObject:insertDict forKey:key];
        }
        else
        {
            [session setJson:insertDict forKey:key];
        }
    }
    else if(query.type==UMDBQUERYTYPE_UPDATE_BY_KEY)
    {
        NSMutableDictionary *updateDict = [[NSMutableDictionary alloc]init];
        NSUInteger i;
        NSUInteger n = query.fields.count;
        for(i=0;i<n;i++)
        {
            updateDict[query.fields[i]]=params[i] ? params[i] : [NSNull null] ;
        }
        
        if (query.table.pool.dbStorageType == UMDBSTORAGE_HASH)
        {
            /* reply = */[session hSetObject:updateDict forKey:key];
        }
        else
        {
            /* reply = */[session updateJsonObject:updateDict forKey:key];
        }
    }
    else if(query.type==UMDBQUERYTYPE_DELETE_BY_KEY)
    {
        /* reply = */[session delObjectForKey:key];
    }
    else if(query.type ==UMDBQUERYTYPE_EXPIRE_KEY)
    {
        /*reply = */[session expireKey:key inSeconds:params[0]];
    }
    else if(query.type==UMDBQUERYTYPE_DELETE_IN_LIST_BY_KEY_AND_VALUE)
    {
        if((params.count !=1) || (query.fields.count !=1))
        {
            @throw([NSException exceptionWithName:@"delete by key and value needs one fields and one parameter"
                                           reason:NULL
                                         userInfo:@{
                                                    @"sysmsg" : @"delete by key and value needs one fields and one parameter",
                                                    @"func": @(__func__),
                                                    @"err": @(-1)
                                                    }]);

        }

        UMJsonWriter *writer = [[UMJsonWriter alloc]init];
        NSString *jsonString = [writer stringWithObject:@{query.primaryKeyName: primaryKeyValue,
                                                          query.fields[0]:params[0]}];
        /* reply = */[session listDelForKey:key andValue:jsonString];
    }
    else if(query.type==UMDBQUERYTYPE_SELECT_BY_KEY)
    {
        @throw([NSException exceptionWithName:@"redis"  reason:@"Select by key without a return value doesnt make much sense" userInfo:NULL]);

    }
    else if(query.type== UMDBQUERYTYPE_INCREASE_BY_KEY)
    {
        NSMutableDictionary *increaseDict = [[NSMutableDictionary alloc]init];
        NSUInteger i;
        NSUInteger n = query.fields.count;
        for(i=0;i<n;i++)
        {
            increaseDict[query.fields[i]]=params[i] ? params[i] : [NSNull null] ;
        }
        
        if (query.table.pool.dbStorageType == UMDBSTORAGE_HASH)
        {
            @throw([NSException exceptionWithName:@"db" reason:@"not yet impelmented for hash" userInfo:NULL]);
            //reply = [session hIncreaseObject:dict forKey:key];
        }
        else
        {
            /* reply = */[session increaseJsonObject:increaseDict forKey:key];
        }
    }
    
#if 0

    NSString *redis = [query redisForType:[query type] forDriver:[pool dbDriverType] parameters:array primaryKeyValue:primaryKeyValue];
    [pool increaseCountersForType:[query type] table:[query table]];
    if(redis == NULL)
    {
        return YES; /* nothing to be done so we succeed */
    }
    BOOL result = [self queryWithNoResult:redis type:[query type] allowFail:failPermission affectedRows:NULL];
#endif
  //  NSLog(@"Reply: %@",reply);

    long long stop = [UMUtil milisecondClock];
    double delay = ((double)(stop - start))/1000000.0;
    [pool addStatDelay:delay query:[query type] table:[query table]];

    return YES;
}

- (BOOL)cachedQueryWithNoResult:(UMDbQuery *)query parameters:(NSArray *)params
{
    return [self cachedQueryWithNoResult:query parameters:params allowFail:NO];
}

- (BOOL)cachedQueryWithNoResult:(UMDbQuery *)query
{
    return [self cachedQueryWithNoResult:query parameters:NULL];
}


- (UMDbResult *)cachedQueryWithMultipleRowsResult:(UMDbQuery *)query
{
    return [self cachedQueryWithMultipleRowsResult:query parameters:NULL];
}

- (UMDbResult *)cachedQueryWithMultipleRowsResult:(UMDbQuery *)query
                                       parameters:(NSArray *)params
                                        allowFail:(BOOL)failPermission
{
    return [self cachedQueryWithMultipleRowsResult:query
                                        parameters:params
                                         allowFail:failPermission
                                   primaryKeyValue:NULL
                                              file:NULL
                                              line:0];

}

- (UMDbResult *)cachedQueryWithMultipleRowsResult:(UMDbQuery *)query
                                       parameters:(NSArray *)params
                                        allowFail:(BOOL)failPermission
                                  primaryKeyValue:(id)primaryKeyValue
{
    return [self cachedQueryWithMultipleRowsResult:query
                                        parameters:params
                                         allowFail:failPermission
                                   primaryKeyValue:primaryKeyValue
                                               file:NULL
                                               line:0];
    
}

- (UMDbResult *)cachedQueryWithMultipleRowsResult:(UMDbQuery *)query
                                       parameters:(NSArray *)params
                                        allowFail:(BOOL)failPermission
                                  primaryKeyValue:(id)primaryKeyValue
                                             file:(const char *)file
                                             line:(long) line
{
    [pool increaseCountersForType:[query type] table:[query table]];
    long long start = [UMUtil milisecondClock];

    UMDbResult *result = nil;
    
    
    NSString *key = [query keyForParameters:params];
    id reply = NULL;

    if(query.type == UMDBQUERYTYPE_SELECT_BY_KEY)
    {
        if (query.storageType == UMDBSTORAGE_HASH)
        {
            reply = [session hGetAllObjectForKey:key];
        }
        else
        {
            reply = [session getJsonForKey:key];
        }
    }
    else if(query.type == UMDBQUERYTYPE_SELECT_LIST_BY_KEY_LIKE)
    {
        NSMutableArray *totalResult = [[NSMutableArray alloc]init];
        id reply1 = [session getKeys:key];
        if([reply1 isKindOfClass:[NSArray class]])
        {
            for(NSData *key2 in reply1)
            {
               //NSLog(@"%@",[key2 description]);
                id reply2 = [session getListForKey:key2];
                if([reply2 isKindOfClass:[NSArray class]])
                {
                    [totalResult addObjectsFromArray:reply2];
                }
            }
            reply = totalResult;
        }
        else
        {
            reply = reply1;
        }
    }
    else if(query.type == UMDBQUERYTYPE_SELECT_BY_KEY_FROM_LIST)
    {
        reply = [session getListForKey:key];
    }
    
    if(reply==NULL)
    {
        return NULL;
    }

    // This an empty Json reply
    if ([reply isKindOfClass:[NSNull class]])
    {
        return nil;
    }

    
    if ([reply isKindOfClass:[UMRedisStatus class]])
    {
        NSLog(@"Redis returns error: %@",reply);
        return NULL;
//        @throw( [NSException exceptionWithName:@"redis" reason:@"query exception" userInfo:@{@"reply" : reply}]);
    }

  
    else if ([reply isKindOfClass:[NSDictionary class]])
    {
        id item = nil;
        long count = [reply count];

        if (count == 0)
        {
            return nil;
        }
        if(file)
        {
            result = [[UMDbResult alloc]initForFile:file line:line];
        }
        else
        {
            result = [[UMDbResult alloc]init];
        }
        result.affectedRows=1;            //HGET would rety+urn only one row in the database sense
        
        NSUInteger i = 0;
        NSArray *keys = [reply allKeys];
        for (NSString *key in keys)
        {
            [result setColumName:key forIndex:i];
            ++i;
        }
        
        NSUInteger n = query.fields.count;
        NSMutableArray *row = [NSMutableArray arrayWithCapacity:n];

        for(i=0;i<n;i++)
        {
            NSString *key = query.fields[i];
            item = [reply objectForKey:key];

            NSString *itemStr;
            if([item isKindOfClass:[NSData class]])
            {
                itemStr = [[NSString alloc] initWithData:item encoding:NSUTF8StringEncoding];
            }
            else if([item isKindOfClass:[NSString class]])
            {
                itemStr = item;
            }
            else if([item isKindOfClass:[NSNumber class]])
            {
                itemStr = [item stringValue];
            }
            else if([item isKindOfClass:[NSNull class]])
            {
                itemStr = @"";
            }
            else if(item ==NULL)
            {
                itemStr = @"";
            }
            else
            {
                NSLog(@"unexpected type: %@ =  %@", [reply class],reply);
            }
            if(itemStr)
            {
                row[i] = itemStr;
            }
        }
        [result addRow:row];
    }
    else if ([reply isKindOfClass:[NSArray class]])
    {
        if(file)
        {
            result = [[UMDbResult alloc]initForFile:file line:line];
        }
        else
        {
            result = [[UMDbResult alloc]init];
        }
        result.resultArray = reply;
    }
    
    long long stop = [UMUtil milisecondClock];
    double delay = ((double)(stop - start))/1000000.0;
    [pool addStatDelay:delay query:[query type] table:[query table]];
    return result;
}

- (UMDbResult *)cachedQueryWithMultipleRowsResult:(UMDbQuery *)query parameters:(NSArray *)params
{
    return [self cachedQueryWithMultipleRowsResult:query parameters:params allowFail:NO];
}

- (BOOL)queryWithNoResult:(NSString *)redis type:(UMDbQueryType) type allowFail:(BOOL)failPermission affectedRows:(unsigned long long *)count;
{
    
    @throw([NSException exceptionWithName:@"why are we calling this?"
                                   reason:NULL
                                 userInfo:@{
                                            @"sysmsg" : @"why are we calling this?",
                                            @"func": @(__func__),
                                            @"err": @(-1)
                                            }]);
#ifdef REDIS_DEBUG
    NSLog(@"REDIS: %@",redis);
#endif
    
    BOOL success = YES;
    NSString *key = nil;
    NSMutableString *value = nil;
    NSData *valueData = nil;
    NSDictionary *valueDict = nil;
    NSString *reply = NULL;
    if(count)
    {
        *count = 0;
    }
    if (type == UMDBQUERYTYPE_INSERT_BY_KEY)
    {
        if (pool.dbStorageType == UMDBSTORAGE_JSON)
        {
            reply = [session setObject:valueData forKey:key];
        }
        else if (pool.dbStorageType == UMDBSTORAGE_HASH)
        {
            reply = [session hSetObject:valueDict forKey:key];
        }
    }

    if (type != UMREDISTYPE_DEL)
    {
        NSRange space = [redis rangeOfString:@" "];
        if (space.location == NSNotFound)
        {
            return NO;
        }
        key = [redis substringToIndex:space.location];
        value = [[redis substringFromIndex:space.location + 1] mutableCopy];
        
        if (pool.dbStorageType == UMDBSTORAGE_HASH)
        {
            valueData = [value dataUsingEncoding:NSUTF8StringEncoding];
            UMJsonParser *parser = [[UMJsonParser alloc] init];
            valueDict = [parser objectWithData:valueData];
        }
        else if (pool.dbStorageType == UMDBSTORAGE_JSON)
        {
            valueData = [value dataUsingEncoding:NSUTF8StringEncoding];
        }
    }
    
    else if (type == UMREDISTYPE_SET)
    {
        if (pool.dbStorageType == UMDBSTORAGE_JSON)
        {
            reply = [session setObject:valueData forKey:key];
        }
        else if (pool.dbStorageType == UMDBSTORAGE_HASH)
        {
            reply = [session hSetObject:valueDict forKey:key];
        }
    }
    else if (type == UMREDISTYPE_DEL)
    {
        reply = [session delObjectForKey:redis];
    }
    else if (type == UMREDISTYPE_UPDATE)
    {
        reply = [session updateObject:valueData forKey:key];
    }
    
    if (type == UMREDISTYPE_SET || type == UMREDISTYPE_UPDATE)
    {
        BOOL isOK = NO;
        if (pool.dbStorageType == UMDBSTORAGE_JSON)
        {
            isOK = [reply isEqualToString:REDIS_RETURN_OK];
        }
        else if (pool.dbStorageType == UMDBSTORAGE_HASH)
        {
            if (type == UMREDISTYPE_SET)
            {
                if ([reply isEqualToString:REDIS_RETURN_INSERTED])
                {
                    isOK = YES;
                }
                else if ([reply isEqualToString:REDIS_RETURN_UPDATED])    // Wrong return value
                {
                    isOK = NO;
                }
                else if ([reply isEqualToString:REDIS_RETURN_EXCEPTION])   // Wrong return value
                {
                    sessionStatus = UMDBSESSION_STATUS_DISCONNECTED;
                    [self reconnect];
                    isOK = NO;
                }
            }
            else if (type == UMREDISTYPE_UPDATE)
            {
                if ([reply isEqualToString:REDIS_RETURN_UPDATED])
                {
                    isOK = YES;
                }
                else if ([reply isEqualToString:REDIS_RETURN_INSERTED])
                {
                    isOK = NO;
                }
                else if ([reply isEqualToString:REDIS_RETURN_EXCEPTION])
                {
                    sessionStatus = UMDBSESSION_STATUS_DISCONNECTED;
                    [self reconnect];
                    isOK = NO;
                }
            }
        }
        
        if (!isOK)
        {
            if (failPermission)
            {
                success = NO;
                [self.logFeed majorError:0 inSubsection:@"redis" withText:reply];
            }
            else
            {
                NSString *reason = [NSString stringWithFormat:@"query failed, redis = %@, error=%@",redis, reply];
                @throw [NSException exceptionWithName:@"NSObjectNotAvailableException" reason:reason userInfo:nil];
            }
        }
    }
    else if (type == UMREDISTYPE_DEL)
    {
        if ([reply isKindOfClass:[NSNumber class]])
        {
            success = YES;
        }
        else
            success = NO;
    }
    
#ifdef REDIS_DEBUG
    if(success)
    {
        [self.logFeed debug:0 inSubsection:@"redis" withText:@"==SUCCESS=="];
    }
    else
    {
        [self.logFeed debug:0 inSubsection:@"redis" withText:@"==FAILURE=="];
    }
#endif
    return success;
}


- (UMDbResult *)queryWithMultipleRowsResult:(NSString *)sql
                                  allowFail:(BOOL)failPermission
{
    return [self queryWithMultipleRowsResult:sql
                                   allowFail:failPermission
                                        file:NULL
                                        line:0];
}

- (UMDbResult *)queryWithMultipleRowsResult:(NSString *)redis
                                  allowFail:(BOOL)failPermission
                                       file:(const char *)file
                                       line:(long)line
{
    UMDbResult *result = nil;
    
#ifdef REDID_DEBUG
    NSLog(@"REDIS: %@",redis);
#endif
    if([redis length]==0)
    {
        return nil;
    }
    id reply = NULL;
    if (pool.dbStorageType == UMDBSTORAGE_JSON)
    {
        reply = [session getObjectForKey:redis];
    }
    else if (pool.dbStorageType == UMDBSTORAGE_HASH)
    {
        reply = [session hGetAllObjectForKey:redis];
    }
    
    if ([reply isKindOfClass:[UMRedisStatus class]])
    {
        BOOL isOK = [reply ok];
        if (!isOK)
        {
            BOOL exceptionRaised = [reply exceptionRaised];
            if (failPermission)
            {
                if (exceptionRaised)
                {
                    sessionStatus = UMDBSESSION_STATUS_DISCONNECTED;
                    [self reconnect];
                }
                
                NSString *msg = [reply statusString];
                [self.logFeed majorError:0 inSubsection:@"redis" withText:msg];
                return nil;
            }
            else
            {
                NSString *reason = [NSString stringWithFormat:@"query failed, redis = %@, error=%@",redis, [reply statusString]];
                @throw [NSException exceptionWithName:@"NSObjectNotAvailableException" reason:reason userInfo:nil];
            }
        }
    }
    
    // This an empty Json reply
    if ([reply isKindOfClass:[NSNull class]])
    {
        return nil;
    }
    
    // This is OK Json reply
    else if ([reply isKindOfClass:[NSData class]])
    {
        NSMutableString *replyString = [[NSMutableString alloc] initWithData:reply encoding:NSUTF8StringEncoding];
        //NSLog(@"we have result %@ in query", replyString);
        [replyString replaceOccurrencesOfString:@"{" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [replyString length])];
        [replyString replaceOccurrencesOfString:@"}" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [replyString length])];
        [replyString replaceOccurrencesOfString:@"\"" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [replyString length])];
        NSArray *replyArray = [replyString componentsSeparatedByString:@", "];
        if(file)
        {
            result = [[UMDbResult alloc]initForFile:file line:line];
        }
        else
        {
            result = [[UMDbResult alloc]init];
            result.affectedRows=replyArray.count;
        }
        if(replyArray && [replyArray count] > 0)
        {
            long columnsCount = [replyArray count];
            long i;
            for(i = 0; i < columnsCount; i++)
            {
                NSString *item = replyArray[i];
                NSArray *pair = [item componentsSeparatedByString:@": "];
                NSString *first = pair[0];
                [result setColumName:first forIndex:i];
            }
        
            NSMutableArray *arr = [[NSMutableArray alloc]init];
            for (i = 0; i < columnsCount; i++)
            {
                NSString *item = replyArray[i];
                NSArray *pair = [item componentsSeparatedByString:@": "];
                NSString *two = pair[1];
                [arr addObject:two];
            }
        
            [result addRow:arr];
        }
    }
    
    // This is OK hash reply. If no data was returned, we got an empty dictionary
    else if ([reply isKindOfClass:[NSDictionary class]])
    {
        long count;
        NSData *item = nil;
        
        if ((count = [reply count]) == 0)
            return nil;
        
        if(file)
        {
            result = [[UMDbResult alloc]initForFile:file line:line];
        }
        else
        {
            result = [[UMDbResult alloc]init];
        }
        result.affectedRows=1;
        long i = 0;
        NSArray *keys = [reply allKeys];
        for (NSString *key in keys)
        {
            [result setColumName:key forIndex:i];
            ++i;
        }

        i = 0;
        NSMutableArray *row = [NSMutableArray arrayWithCapacity:count];
        [row addObjectsFromArray:[reply allValues]];
        while (i < count)
        {
            item = row[i];
            NSString *itemStr = [[NSString alloc] initWithData:item encoding:NSUTF8StringEncoding];
            row[i] = itemStr;
            ++i;
        }
        [result addRow:row];
    }
    
    return result;
}

/*Statistical data for current hour*/
- (NSMutableArray *)currentStat
{
    NSMutableArray *resultArray = [[NSMutableArray alloc] init];
    
    id reply = [session getLike];
    if ([reply isKindOfClass:[UMRedisStatus class]])
    {
        BOOL isOK = [reply ok];
        if (!isOK)
        {
            BOOL exceptionRaised = [reply exceptionRaised];
            if (exceptionRaised)
            {
                sessionStatus = UMDBSESSION_STATUS_DISCONNECTED;
                [self reconnect];
            }
            
            NSString *msg = [reply statusString];
            [self.logFeed majorError:0 inSubsection:@"redis" withText:msg];
            return nil;
        }
    }
    
    if ([reply isKindOfClass:[NSNull class]])
    {
        return nil;
    }
    
    if ([reply isKindOfClass:[NSArray class]])
    {
        long count = [reply count];
        if (count <1)
            return nil;
    
        long i = 0;
        while (i < count)
        {
            NSData *key = reply[i];
            NSString *keyString = [[NSString alloc] initWithData:key encoding:NSUTF8StringEncoding];
            UMDbResult *result = [self queryWithMultipleRowsResult:keyString allowFail:YES];
            
            // Add operator name from key
            NSArray *parts = [keyString componentsSeparatedByString:@":"];
            long count = [parts count];
            NSString *operatorString = parts[count - 1];
            [[result columNames] addObject:@"operator"];
            [[result resultArray][0] addObject:operatorString];
            
            [resultArray addObject:result];
            ++i;
        }
    }
    return resultArray;
}

- (BOOL)deleteCurrent
{
    BOOL success = NO;
    
    id reply = [session getLike];
    if ([reply isKindOfClass:[UMRedisStatus class]])
    {
        BOOL isOK = [reply ok];
        if (!isOK)
        {
            BOOL exceptionRaised = [reply exceptionRaised];
            if (exceptionRaised) {
                sessionStatus = UMDBSESSION_STATUS_DISCONNECTED;
                [self reconnect];
            }
            
            NSString *msg = [reply statusString];
            [self.logFeed majorError:0 inSubsection:@"redis" withText:msg];
            return success;
        }
    }
    
    // Nothing to be deleted
    if ([reply isKindOfClass:[NSNull class]])
    {
        return YES;
    }
    
    if ([reply isKindOfClass:[NSArray class]])
    {
        long count = [reply count];
        if (count < 1)
            return YES;
        
        long i = 0;
        while (i < count)
        {
            NSData *key = reply[i];
            NSString *keyString = [[NSString alloc] initWithData:key encoding:NSUTF8StringEncoding];
            NSString *reply = [session delObjectForKey:keyString];
            if ([reply length]>0)
                return NO;
            ++i;
        }
    }
    return success;
}

- (int) hexistField:(NSString *)field ofKey:(NSString *)key allowFail:(BOOL)failPermission
{
    int exists = 0;
    
    NSString *reply = [session hexistField:field ofKey:key];
    if ([reply isEqualToString:REDIS_RETURN_EXISTS])
    {
        exists = 1;
    }
    else if ([reply isEqualToString:REDIS_RETURN_EXCEPTION])
    {
        if (!failPermission)
        {
            NSString *reason = [NSString stringWithFormat:@"ewdis query failed, field = %@, key=%@ socket exception raised", field, key];
            @throw [NSException exceptionWithName:@"NSObjectNotAvailableException" reason:reason userInfo:nil];
        }
        else
        {
            sessionStatus = UMDBSESSION_STATUS_DISCONNECTED;
            [self reconnect];
            exists = -1;
        }
    }
    
    return exists;
}

/* Hincr is not idempotent, so we need unique key for stored queries. */
- (NSNumber *) hincrFields:(NSArray *)arr ofKey:(NSString *)key by:(NSNumber *)incr incrementIsInteger:(BOOL)flag allowFail:(BOOL)failPermission withId:(NSString *)qid;
{
    NSNumber *currentValue;
    NSString *reply = nil;
    NSString *retString;
    BOOL success = NO;
    NSMutableString *queryKey = [NSMutableString stringWithString:key];
    [queryKey appendString:qid];
    
    if (flag == YES)
    {
        reply = [session hincrFields:arr ofKey:key by:[incr intValue]];
    }
    else
    {
        reply = [session hincrFields:arr ofKey:key byFloat:[incr floatValue]];
    }
    
    if ([reply isEqualToString:REDIS_RETURN_EXCEPTION])
    {
        if (failPermission)
        {
            sessionStatus = UMDBSESSION_STATUS_DISCONNECTED;
            success = [self reconnect];
            if (success)
                reply = REDIS_RETURN_FAILURE;
        }
        else
        {
            NSString *reason = [NSString stringWithFormat:@"redis query failed, array = %@, key=%@ socket exception raised", arr, key];
            @throw [NSException exceptionWithName:@"NSObjectNotAvailableException" reason:reason userInfo:nil];
        }
    }
    
    retString = [reply substringFromIndex:1];
    
    if (flag == YES)
    {
        int ret = [retString intValue];
        currentValue = @(ret);
    }
    else
    {
        float ret = [retString floatValue];
        currentValue = @(ret);
    }
    return currentValue;
}

- (BOOL) ping
{
    NSString *reply = nil;
    BOOL success = NO;
    
    reply = [session ping];
    if ([reply isEqualToString:REDIS_RETURN_EXCEPTION])
    {
        sessionStatus = UMDBSESSION_STATUS_DISCONNECTED;
        [self reconnect];
        success = NO;
    }
    else if ([reply isEqualToString:REDIS_RETURN_PING_OK])
    {
        success = YES;
    }
    else
    {
        success = NO;
    }
    
    return success;
}

- (int)errorCheck:(NSString  *)reply
{
    if ([reply characterAtIndex:0] == '-')
        return -1;
    return 0;
}



@end
