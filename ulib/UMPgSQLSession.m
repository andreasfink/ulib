//
//  UMPgSQLSession.m
//  ulibdb.framework
//
//  Created by Andreas Fink on 21.10.11.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.


#import <ulib/ulib.h>
#import <ulib/ulib_config.h>
#import <ulib/UMDbPool.h>
#import <ulib/UMDbSession.h>
#import <ulib/UMDbResult.h>
#import <ulib/UMPgSQLSession.h>

#include <stdio.h>

#ifdef HAVE_PGSQL
#include  <libpq-fe.h>
#endif

@implementation UMPgSQLSession

- (UMPgSQLSession *)initWithPool:(UMDbPool *)dbpool
{
#ifdef HAVE_PGSQL
    if (!dbpool)
    {
        return nil;
    }
    self=[super initWithPool:dbpool];
    if(self)
    {
        if(PQisthreadsafe()==0)
        {
            NSLog(@"int PQisthreadsafe() returns 0! Please use threadsave version of libpq");
            __builtin_trap();
        }
    }
    return self;
#else
    return NULL;
#endif
}
- (void)dealloc
{
    if(sessionStatus == UMDBSESSION_STATUS_CONNECTED)
    {
        [self disconnect];
    }
}

- (BOOL) connect
{
    NSMutableString *connectString = [[NSMutableString alloc]init];
    if([pool hostName]>0)
    {
        [connectString appendFormat:@"host=%@ ", [pool hostName]];
    }
    if([pool port]>0)
    {
        [connectString appendFormat:@"port=%d ", [pool port]];
    }
    if([[pool user] length] > 0)
    {
        [connectString appendFormat:@"user=%@ ", [pool user]];
    }
    if([[pool pass] length] > 0)
    {
        [connectString appendFormat:@"password=%@ ", [pool pass]];
    }

    if([[pool dbName] length] > 0)
    {
        [connectString appendFormat:@"dbname=%@ ", [pool dbName]];
    }
    if([[pool options] length] > 0)
    {
        [connectString appendFormat:@"options=%@ ", [pool options]];
    }
    [connectString appendFormat:@"keepalives=1 "];
    /* See http://www.postgresql.org/docs/9.0/interactive/libpq-connect.html for additional parameters */
#ifdef HAVE_PGSQL
    pgconn = PQconnectdb([connectString UTF8String]);
    if(pgconn)
    {
        sessionStatus = UMDBSESSION_STATUS_CONNECTED;
        return YES;
    }
#else
    sessionStatus = UMDBSESSION_STATUS_DISCONNECTED;
#endif
    return NO;
}

- (void)disconnect
{
    if(sessionStatus == UMDBSESSION_STATUS_CONNECTED)
    {
        sessionStatus = UMDBSESSION_STATUS_DISCONNECTED;
#ifdef HAVE_PGSQL
        PQfinish(pgconn);
#endif
        pgconn = NULL;
    }
}

- (BOOL)ping 
{
#ifdef HAVE_PGSQL
    if (PQstatus(pgconn) == CONNECTION_BAD)
    {    
        NSLog(@"PGSQL: Database check failed!");
        NSLog(@"PGSQL: %s", PQerrorMessage(pgconn));
        return NO;
    }	
//    PGPing PQpingParams(const char **keywords, const char **values, int expand_dbname);
    return YES;
#else
    return YES; /* if we would return NO here, it would constantly trigger reconnection on invalid connection*/
#endif
}


- (UMDbResult *)queryWithMultipleRowsResult:(NSString *)sql allowFail:(BOOL)failPermission
{
    return [self queryWithMultipleRowsResult:sql allowFail:failPermission file:NULL line:0];
}

- (UMDbResult *)queryWithMultipleRowsResult:(NSString *)sql
                                  allowFail:(BOOL)failPermission
                                       file:(const char *)file
                                       line:(long)line
{
#ifdef HAVE_PGSQL
#ifdef PGSQL_DEBUG
    NSLog(@"SQL: %@",sql);
#endif
    if([sql length]==0)
    {
        return NULL;
    }
    PGresult *res = PQexec(pgconn, [sql UTF8String]);
    switch (PQresultStatus(res))
    {
        case PGRES_EMPTY_QUERY:
        case PGRES_BAD_RESPONSE:
        case PGRES_NONFATAL_ERROR:
        case PGRES_FATAL_ERROR:
            NSLog(@"PGSQL: %s", [sql UTF8String]);
            NSLog(@"PGSQL: %s", PQresultErrorMessage(res));
            PQclear(res);
            return NULL;
        default: /* for compiler please */
            break;
    }
    UMDbResult *result;
    if(file)
    {
        result = [[UMDbResult alloc]initForFile:file line:line];
    }
    else
    {
        result = [[UMDbResult alloc] init];
    }
    int nTuples = PQntuples(res);
    int nFields = PQnfields(res);
    int row_loop;
    int field_loop;
    
    for(field_loop=0;field_loop<nFields;field_loop++)
    {
        [result setColumName:@(PQfname(res,field_loop)) forIndex:field_loop];
    }

    for (row_loop = 0; row_loop < nTuples; row_loop++)
    {
        NSMutableArray *row = [[NSMutableArray alloc]init];
    	for (field_loop = 0; field_loop < nFields; field_loop++)
        {
            if (PQgetisnull(res, row_loop, field_loop))
                [row addObject:@""];
            else 
            {
                NSString *s =@(PQgetvalue(res, row_loop, field_loop));
                s = [s stringByTrimmingCharactersInSet:[UMObject whitespaceAndNewlineCharacterSet]];
                [row addObject:s];
            }
        }
        [result addRow:row];
    }
    int affectedRows = [@(PQcmdTuples(res))intValue];
    result.affectedRows = affectedRows;
    PQclear(res);
    return result;
#else
    return NULL;
#endif
}


- (BOOL)queryWithNoResult:(NSString *)line allowFail:(BOOL)canFail affectedRows:(unsigned long long *)count
{
#ifdef HAVE_PGSQL
    BOOL success=YES;
#ifdef PGSQL_DEBUG
    NSLog(@"SQL: %@",line);
#endif
    line = [line stringByTrimmingCharactersInSet:[UMObject whitespaceAndNewlineCharacterSet]];
    if([line length]==0)
    {
        return YES;
    }
    if(count != NULL)
    {
        *count = 0;
    }
    PGresult *res = PQexec(pgconn, [line UTF8String]);
    if (res == NULL)
        return NO;
    switch (PQresultStatus(res))
    {
        case PGRES_EMPTY_QUERY:
            break;
        case PGRES_BAD_RESPONSE:
        case PGRES_NONFATAL_ERROR:
            NSLog(@"PGSQL: %s", [line UTF8String]);
            NSLog(@"PGSQL: %s", PQresultErrorMessage(res));
            success = NO;
            break;
        case PGRES_FATAL_ERROR:
            NSLog(@"PGSQL: %s", [line UTF8String]);
            if(canFail)
                NSLog(@"PGSQL: %s", PQresultErrorMessage(res));
            else
                NSLog(@"PGSQL: %s", PQresultErrorMessage(res));
            success = NO;
            break;
        case PGRES_COMMAND_OK:
            break;
        default: /* for compiler please */
            success = NO;
    }
    PQclear(res);
    return success;
#else
    return NO;
#endif
}

- (char)fieldQuoteChar
{
    return '\"';
}

@end

