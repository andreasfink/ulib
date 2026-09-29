//
//  UMPgSQLSession.h
//  ulibdb.framework
//
//  Created by Andreas Fink on 21.10.11.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.

#import <ulib/UMDbSession.h>


#define DEFAULT_PGSQL_PORT 5432
//#define PGSQL_DEBUG 1

@interface UMPgSQLSession : UMDbSession
{
    NSString        *pgtty;
    /* PGconn */ void            *pgconn;
}


- (UMPgSQLSession *)initWithPool:(UMDbPool *)dbpool;
- (void) dealloc;

- (BOOL) connect;
- (void) disconnect;
- (BOOL)queryWithNoResult:(NSString *)sql allowFail:(BOOL)failPermission affectedRows:(unsigned long long *)count;
- (UMDbResult *)queryWithMultipleRowsResult:(NSString *)sql allowFail:(BOOL)failPermission;
- (UMDbResult *)queryWithMultipleRowsResult:(NSString *)sql
                                  allowFail:(BOOL)failPermission
                                       file:(const char *)file
                                       line:(long)line;
- (BOOL)ping;

@end

