//
//  UMDbSession.m
//  ulibdb.framework
//
//  Created by Andreas Fink on 24.10.11.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.

#import <ulib/UMObject.h>
#import <ulib/ulib_config.h>
#import <ulib/UMDbSession.h>
#import <ulib/UMDbPool.h>
#import <ulib/UMDbResult.h>
#import <ulib/UMDbQuery.h>
#import <ulib/UMDbDriverType.h>
#import <ulib/UMAssert.h>
#import <ulib/NSString+ulib.h>
#import <ulib/NSDate+ulib.h>
#import <ulib/UMUtil.h>

@implementation UMDbSession

@synthesize pool;
@synthesize usedFile;
@synthesize usedLine;
@synthesize usedFunction;
@synthesize usedQuery;


@synthesize lastUsedFile;
@synthesize lastUsedLine;
@synthesize lastUsedFunction;
@synthesize lastUsedQuery;

@synthesize name;
@synthesize sessionStatus;

- (UMDbSession *)initWithPool:(UMDbPool *)dbpool
{
    if (!dbpool)
    {
        return nil;
    }
    self = [super init];
    if(self)
    {
        pool = dbpool;
        _sessionLock = [[UMMutex alloc]initWithName:@"db-session-lock"];
    }
    return self;
}

- (void) dealloc
{
    if(sessionStatus == UMDBSESSION_STATUS_CONNECTED)
    {
        [self disconnect];
    }
}

- (NSString *)description
{
    NSMutableString *desc = [NSMutableString stringWithString:@"session dump starts\r\n"];
    [desc appendFormat:@"pool %@\r\n", pool];
    [desc appendFormat:@"grab time %ld\r\n", grabTime];
    [desc appendFormat:@"return time %ld\r\n", returnTime];
    [desc appendFormat:@"session status %@\r\n", [self sessionStatusToString]];
    [desc appendFormat:@"versioin %@\r\n", versionString];
    [desc appendFormat:@"used file %@\r\n", usedFile];
    [desc appendFormat:@"used line %ld\r\n", usedLine];
    [desc appendFormat:@"used function %@\r\n", usedFunction];
    [desc appendFormat:@"last used file %@\r\n", lastUsedFile];
    [desc appendFormat:@"last used line %ld\r\n", lastUsedLine];
    [desc appendFormat:@"last used function %@\r\n", lastUsedFunction];
    [desc appendFormat:@"name %@\r\n", name];
    [desc appendString:@"session dump ends\r\n"];
    
    return desc;
}

- (NSString *)sessionStatusToString
{
    switch (sessionStatus)
    {
        case UMDBSESSION_STATUS_CONNECTED:
            return @"connected";
            break;
        case UMDBSESSION_STATUS_DISCONNECTED:
            return @"disconnected";
            break;
    }
    
    return @"N.N.";
}

- (BOOL) ping
{
    return YES;
}

- (void) touchGrabTimer
{
    time(&grabTime);
}

- (void) touchReturnTimer
{
    time(&returnTime);
}

- (BOOL) connect
{
    return YES; /* note the not subclassed DB simulates a NULL DB so all queries will succeed doing nothing */
}

- (BOOL) reconnect
{
    return YES; /* note the not subclassed DB simulates a NULL DB so all queries will succeed doing nothing */
}


- (void) disconnect
{
   /* note the not subclassed DB simulates a NULL DB so we do nothing */ 
}

- (BOOL) isConnected
{
    return sessionStatus == UMDBSESSION_STATUS_CONNECTED;
}

- (BOOL)startTransaction /* returns success */
{
    unsigned long long count = 0;
    BOOL result = [self queryWithNoResult:@"START TRANSACTION" allowFail:NO affectedRows:&count];
    return result;
}

- (BOOL)commitTransaction /* returns success */
{
    unsigned long long count = 0;
    BOOL result = [self queryWithNoResult:@"COMMIT" allowFail:NO affectedRows:&count];
    return result;

}

-(BOOL)rollbackTransaction /* returns success */
{
    unsigned long long count = 0;
    BOOL result = [self queryWithNoResult:@"ROLLBACK" allowFail:NO affectedRows:&count];
    return result;
}


- (BOOL)queryWithNoResult:(UMDbQuery *)query
               parameters:(NSArray *)array
                allowFail:(BOOL)failPermission
          primaryKeyValue:(id)primaryKeyValue
             affectedRows:(unsigned long long *)count
{
    BOOL result =NO;
    
    if(query.returnsResult)
    {
        UMAssert(0,@"Query returns result but we are not expecting any");
    }
    ummutex_lock(_sessionLock);
    @try
    {
        NSString *sql = [query sqlForType:query.type
                                forDriver:pool.dbDriverType
                                  session:self
                               parameters:array
                          primaryKeyValue:primaryKeyValue];
        query.lastSql = sql;
        [pool increaseCountersForType:[query type] table:[query table]];
        long long start = [UMUtil milisecondClock];
        if(sql == NULL)
        {
            return YES; /* nothing to be done so we succeed */
        }
        result = [self queryWithNoResult:sql allowFail:failPermission affectedRows:count];

        long long stop = [UMUtil milisecondClock];
        double delay = ((double)(stop - start))/1000000.0;
        [pool addStatDelay:delay query:[query type] table:[query table]];
    }
    @finally
    {
        ummutex_unlock(_sessionLock);
    }
    return result;
}
- (BOOL)cachedQueryWithNoResult:(UMDbQuery *)query
                     parameters:(NSArray *)array
                      allowFail:(BOOL)failPermission
                primaryKeyValue:(id)primaryKeyValue
                   affectedRows:(unsigned long long *)count
{
    BOOL result =NO;
    
    if(query.returnsResult)
    {
        UMAssert(0,@"Query returns result but we are not expecting any");
    }

    ummutex_lock(_sessionLock);
    @try
    {
        NSString *sql = [query sqlForType:query.type
                                forDriver:pool.dbDriverType
                                  session:self
                               parameters:array
                          primaryKeyValue:primaryKeyValue];
        query.lastSql = sql;
        [pool increaseCountersForType:[query type] table:[query table]];
        long long start = [UMUtil milisecondClock];
        if(sql == NULL)
        {
            return YES; /* nothing to be done so we succeed */
        }
        result = [self queryWithNoResult:sql allowFail:failPermission affectedRows:count];


        long long stop = [UMUtil milisecondClock];
        double delay = ((double)(stop - start))/1000000.0;
        [pool addStatDelay:delay query:[query type] table:[query table]];
    }
    @finally
    {
        ummutex_unlock(_sessionLock);
    }
    return result;
}

- (BOOL)cachedQueryWithNoResult:(UMDbQuery *)query
                     parameters:(NSArray *)array
                      allowFail:(BOOL)failPermission
                primaryKeyValue:(id)primaryKeyValue
{
    return [self cachedQueryWithNoResult:query
                              parameters:array
                               allowFail:failPermission
                         primaryKeyValue:primaryKeyValue
                            affectedRows:NULL];
}

- (BOOL)cachedQueryWithNoResult:(UMDbQuery *)query parameters:(NSArray *)array allowFail:(BOOL)failPermission
{
    return [self cachedQueryWithNoResult:query parameters:array allowFail:failPermission primaryKeyValue:NULL];
}

- (BOOL)cachedQueryWithNoResult:(UMDbQuery *)query parameters:(NSArray *)params
{
    return [self cachedQueryWithNoResult:query parameters:params allowFail:NO primaryKeyValue:NULL];
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
    return [self cachedQueryWithMultipleRowsResult:query parameters:params allowFail:failPermission primaryKeyValue:NULL];
}

- (UMDbResult *)cachedQueryWithMultipleRowsResult:(UMDbQuery *)query
                                       parameters:(NSArray *)params
                                        allowFail:(BOOL)failPermission
                                  primaryKeyValue:(NSString *)primaryKeyValue
{
    UMDbResult *result=NULL;
    if(query.returnsResult==NO)
    {
        UMAssert(0,@"Query does not result but we are expecting a result");
    }

    ummutex_lock(_sessionLock);
    @try
    {
        NSString *sql = NULL;
        if (!query)
        {
            sql = [query sqlForType:UMDBQUERYTYPE_UNKNOWN
                          forDriver:UMDBDRIVER_NULL
                            session:self
                         parameters:params
                    primaryKeyValue:primaryKeyValue];
        }
        else
        {
            sql = [query sqlForType:query.type
                          forDriver:pool.dbDriverType
                            session:self
                         parameters:params
                    primaryKeyValue:primaryKeyValue];
        }
        query.lastSql = sql;
        [pool increaseCountersForType:[query type] table:[query table]];
        long long start = [UMUtil milisecondClock];
        if(sql == NULL)
        {
            return [[UMDbResult alloc]init];
        }
        result = [self queryWithMultipleRowsResult:sql
                                         allowFail:failPermission
                                              file:query.cfile
                                              line:query.cline];
        
        long long stop = [UMUtil milisecondClock];
        
        double delay = ((double)(stop - start))/1000000.0;
        [pool addStatDelay:delay query:[query type] table:[query table]];
    }
    @finally
    {
        ummutex_unlock(_sessionLock);
    }
    return result;

}
- (UMDbResult *)cachedQueryWithMultipleRowsResult:(UMDbQuery *)query
                                       parameters:(NSArray *)params
{
    return [self cachedQueryWithMultipleRowsResult:query
                                        parameters:params
                                         allowFail:NO];
}


- (UMDbResult *)queryWithMultipleRowsResult:(NSString *)sql allowFail:(BOOL)failPermission
{
    return [self queryWithMultipleRowsResult:sql allowFail:failPermission file:NULL line:0];
}

- (UMDbResult *)queryWithMultipleRowsResult:(NSString *)sql allowFail:(BOOL)failPermission file:(const char *)file line:(long)line
{
    return [[UMDbResult alloc]initForFile:file line:line];
}


- (UMDbResult *)queryWithMultipleRowsResult:(NSString *)sql
{
    return [self queryWithMultipleRowsResult:sql allowFail:NO];
}


- (BOOL)queryWithNoResult:(NSString *)sql /* returns Success */
{
   return [self queryWithNoResult:sql allowFail:NO affectedRows:NULL];
}


- (BOOL)queryWithNoResult:(NSString *)sql allowFail:(BOOL)canFail /* returns Success */
{
    return [self queryWithNoResult:sql allowFail:canFail affectedRows:NULL];
}

- (BOOL)queryWithNoResult:(NSString *)sql allowFail:(BOOL)canFail affectedRows:(unsigned long long *)count/* returns Success */
{
    return YES;
}


- (BOOL)queriesWithNoResult:(NSArray *)sqlStatements allowFail:(BOOL)canFail
{
    BOOL success = YES;
    if([sqlStatements isKindOfClass:[NSString class]])
    {
        /* this is a old app calling us with a string. For compatibility reasons we want to try to fullfill this */
        return [self queriesWithNoResultOld:(NSString *)sqlStatements allowFail:canFail];

    }
    for(NSString *sql in sqlStatements)
    {
        success = success & [self queryWithNoResult:sql allowFail:canFail affectedRows:NULL];
    }
    return success;
}

- (BOOL)queriesWithNoResultOld:(NSString *)sqlStatementText allowFail:(BOOL)canFail
{
    BOOL success = YES;
    NSArray *sqlStatements = [sqlStatementText componentsSeparatedByString:@";"];
    for(NSString *sql in sqlStatements)
    {
        success = success & [self queryWithNoResult:sql allowFail:canFail affectedRows:NULL];
    }
    return success;
}


- (NSMutableArray *)currentStat
{
    return nil;
}

- (BOOL)deleteCurrent
{
    return YES;
}

- (int) hexistField:(NSString *)field ofKey:(NSString *)key  allowFail:(BOOL)failPermission
{
    return YES;
}

- (NSNumber *) hincrFields:(NSArray *)arr ofKey:(NSString *)key by:(NSNumber *)incr incrementIsInteger:(BOOL)flag allowFail:(BOOL)failPermission withId:(NSString *)qid
{
    return @0;
}

- (char)fieldQuoteChar
{
    return '\"';
}


+ (NSString *)prefixFields:(NSString *)fields withTableName:(NSString *)tableName
{
    NSArray *items = [fields componentsSeparatedByString:@","];
    NSMutableString *r = [[NSMutableString alloc]init];
    BOOL first = YES;
    for(NSString *item in items)
    {
        if(first)
        {
            [r appendFormat:@"%@.%@",tableName,item];
            first = NO;
        }
        else
        {
            [r appendFormat:@",%@.%@",tableName,item];
        }
    }
    return r;
}

-(void)setUsedFrom:(const char *)file line:(long)line func:(const char *)func
{
    self.lastUsedFile = self.usedFile;
    self.lastUsedFunction = self.usedFunction;
    self.lastUsedLine = self.usedLine;
    self.lastUsedQuery = self.usedQuery;
    
    self.usedFile = @(file);
    self.usedFunction = @(func);
    self.usedLine = line;
}

- (NSString *)inUseDescription
{
    
    return [NSString stringWithFormat:@"%@ lastActivity: %@:%ld %@",
            [super description],
            self.usedFile,
            self.usedLine,
            self.usedFunction];
}

- (NSString *)sqlEscapeString:(NSString *)in
{
    return [in sqlEscaped];
}

@end
