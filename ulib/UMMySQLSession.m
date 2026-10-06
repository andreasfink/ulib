//
//  UMMySQLSession.m
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
#import <ulib/ulib_config.h>

#import <ulib/UMMySQLSession.h>

#ifdef HAVE_MYSQL
#include <mariadb/mysql.h>
#include <mariadb/errmsg.h>
#include <mariadb/mysqld_error.h>
#endif

#import "UMDbResult.h"
#import "UMDbMySqlInProgress.h"
#import "UMDbQuery.h"

//#define MYSQL_DEBUG 1
@implementation UMMySQLSession

@synthesize type;
@synthesize loghandler;
@synthesize lastInProgress;

- (void *)connection
{
    return connection;
}

- (UMDbSession *)initWithPool:(UMDbPool *)p
{
#ifdef HAVE_MYSQL
    @autoreleasepool
    {
        if (!p)
        {
            return nil;
        }
        self=[super initWithPool:p];
        if(self)
        {
            mysql = calloc(1,sizeof(MYSQL));
            if(mysql)
            {
                mysql_init(mysql);
            }
            connection = NULL;
        }
        return self;
    }
#else
    return NULL;
#endif
}

- (void)dealloc
{
    [self.logFeed info:0 withText:[NSString stringWithFormat:@"UMMySQLConnection '%@'is being deallocated\n",name]];
    if(mysql)
    {
        free(mysql);
    }
    if(connection)
    {
        free(connection);
    }
    name = nil;
}

- (void) setLogHandler:(UMLogHandler *)handler
{
	if( loghandler != handler)
	{
		
		self.logFeed = [[UMLogFeed alloc] initWithHandler:loghandler section:type subsection:@"log"];
		[self.logFeed setCopyToConsole:1];
		[self.logFeed setName:name];
	}
}

- (BOOL) connect
{
#ifdef HAVE_MYSQL
    @autoreleasepool
    {
        MYSQL_RES	*res;
        MYSQL_ROW	row;
        int     state;

        ummutex_lock(_sessionLock);
        @try
        {
            
            char  my_true = 1;
            if (mysql_options(mysql, MYSQL_OPT_RECONNECT, &my_true))
            {
                NSLog(@"mysql_options (MYSQL_OPT_RECONNECT) failed");
            }
            connection = mysql_real_connect(mysql,
                                            (const char *)[[pool hostName]UTF8String],
                                            (const char *)[[pool user]UTF8String],
                                            (const char *)[[pool pass]UTF8String],
                                            (const char *)[[pool dbName]UTF8String],
                                            (unsigned int)[pool port],
                                            (const char *)[[pool socket]UTF8String],
                                            (unsigned long)0);
            if(connection == NULL)
            {
                NSMutableString *reason = [NSMutableString stringWithString:@"Cannot connect to mysql database (mysql_error ["];
                [reason appendFormat:@"%s]) while executing connect", mysql_error(mysql)];
                @throw [NSException exceptionWithName:@"NSDestinationInvalidException" reason:reason userInfo:nil];
                return NO;
            }
            sessionStatus = UMDBSESSION_STATUS_CONNECTED;
            
            const char *query = "show variables like 'version'";
            self.lastInProgress = [[UMDbMySqlInProgress alloc] initWithCString:query previousQuery:lastInProgress];
            state = mysql_query(connection,query);
            [lastInProgress completed];
            
            if(state != 0)
            {
                @throw [NSException exceptionWithName:@"NSObjectNotAvailableException" reason:@"cant use mysql_query" userInfo:nil];
                return NO;
            }
            res = mysql_store_result(connection);
            if(res == 0)
            {
                @throw [NSException exceptionWithName:@"NSObjectNotAvailableException" reason:@"cant use mysql_store_result()" userInfo:nil];
                return NO;
            }
            
            row = mysql_fetch_row(res);
            if(row == 0)
            {
                @throw [NSException exceptionWithName:@"NSObjectNotAvailableException" reason:@"cant use mysql_fetch_row" userInfo:nil];
            }
            versionString = [[NSString alloc]initWithUTF8String:row[1]];
            mysql_free_result(res);
            
            mysqlServerVer =  mysql_get_server_version(connection);
            if(mysqlServerVer < 50619)
            {
                [self.logFeed warning:0 withText:[NSString stringWithFormat:@"MySQL server version is  %ld which is < 5.6.15",mysqlServerVer]];
            }
            mysqlClientVer = mysql_get_client_version();
            if(mysqlServerVer < 50619)
            {
                [self.logFeed warning:0 withText:[NSString stringWithFormat:@"MySQL client version is  %ld which is < 5.0.15",mysqlServerVer]];
            }
            
            query = "set autocommit=1";
            self.lastInProgress = [[UMDbMySqlInProgress alloc]initWithCString:query previousQuery:lastInProgress];
            mysql_query(connection,query);
            [lastInProgress completed];
            
            mysql_options(connection, MYSQL_READ_DEFAULT_FILE,"/etc/my.cnf");
            mysql_options(connection, MYSQL_SET_CHARSET_NAME,"UTF8");
            mysql_set_character_set(connection, "utf8");
            
            char b = 1;
            mysql_options(connection, MYSQL_OPT_RECONNECT,&b);
            //    mysql_options(connection, MYSQL_OPT_CONNECT_TIMEOUT,"1800"); /* 30 minutes */
            //    mysql_options(connection, MYSQL_OPT_COMPRESS,NULL); /* enable compression */
            //   unsigned int timeout = 1800;
            //   mysql_options(connection, MYSQL_OPT_READ_TIMEOUT,&timeout);

            mysql_query(connection,"SET NAMES utf8");
            mysql_query(connection,"SET CHARACTER SET utf8");
            mysql_query(connection,"SET character_set_server = 'utf8'");
            mysql_query(connection,"SET character_set_connection = 'utf8'");
        }
        @finally
        {
            ummutex_unlock(_sessionLock);
        }
        return YES;
    }
#else
    return NO;
#endif
}

- (void) disconnect
{
    if(sessionStatus == UMDBSESSION_STATUS_CONNECTED)
    {
        sessionStatus = UMDBSESSION_STATUS_DISCONNECTED;
#ifdef HAVE_MYSQL
        mysql_close(connection);
#endif
        connection = NULL;
    }
}

- (int)errorCheck:(int) state forSql:(NSString *)sql;
{
    NSString *s;
    
#if !defined(HAVE_MYSQL)
    s = @"CR_UNKNOWN_ERROR";
    return state;
#else
    
#if defined(CR_ERROR_FIRST)
    if(state < CR_ERROR_FIRST)
    {
        return state;
    }
#endif

    switch(state)
    {
        case CR_UNKNOWN_ERROR:
            s = @"CR_UNKNOWN_ERROR";
            break;
        case CR_SOCKET_CREATE_ERROR:
            s = @"CR_SOCKET_CREATE_ERROR";
            break;
        case CR_CONNECTION_ERROR:
            s = @"CR_CONNECTION_ERROR";
            break;
        case CR_CONN_HOST_ERROR:
            s = @"CR_CONN_HOST_ERROR";
            break;
        case CR_IPSOCK_ERROR:
            s = @"CR_IPSOCK_ERROR";
            break;
        case CR_UNKNOWN_HOST:
            s = @"CR_UNKNOWN_HOST";
            break;
        case CR_SERVER_GONE_ERROR:
            s = @"CR_SERVER_GONE_ERROR";
            break;
        case CR_VERSION_ERROR:
            s = @"CR_VERSION_ERROR";
            break;
        case CR_OUT_OF_MEMORY:
            s = @"CR_OUT_OF_MEMORY";
            break;
        case CR_WRONG_HOST_INFO:
            s = @"CR_WRONG_HOST_INFO";
            break;
        case CR_LOCALHOST_CONNECTION:
            s = @"CR_LOCALHOST_CONNECTION";
            break;
        case CR_TCP_CONNECTION:
            s = @"CR_TCP_CONNECTION";
            break;
        case CR_SERVER_HANDSHAKE_ERR:
            s = @"CR_SERVER_HANDSHAKE_ERR";
            break;
        case CR_SERVER_LOST:
            s = @"CR_SERVER_LOST";
            break;
        case CR_COMMANDS_OUT_OF_SYNC:
            s = @"CR_COMMANDS_OUT_OF_SYNC";
            break;
        case CR_NAMEDPIPE_CONNECTION:
            s = @"CR_NAMEDPIPE_CONNECTION";
            break;
        case CR_NAMEDPIPEWAIT_ERROR:
            s = @"CR_NAMEDPIPEWAIT_ERROR";
            break;
        case CR_NAMEDPIPEOPEN_ERROR:
            s = @"CR_NAMEDPIPEOPEN_ERROR";
            break;
        case CR_NAMEDPIPESETSTATE_ERROR:
            s = @"CR_NAMEDPIPESETSTATE_ERROR";
            break;
        case CR_CANT_READ_CHARSET:
            s = @"CR_CANT_READ_CHARSET";
            break;
        case CR_NET_PACKET_TOO_LARGE:
            s = @"CR_NET_PACKET_TOO_LARGE";
            break;

#if defined(CR_EMBEDDED_CONNECTION)
        case CR_EMBEDDED_CONNECTION:
            s = @"CR_EMBEDDED_CONNECTION";
            break;
#endif

#if defined(CR_PROBE_SLAVE_STATUS)
        case CR_PROBE_SLAVE_STATUS:
            s = @"CR_PROBE_SLAVE_STATUS";
            break;
#endif

#if defined(CR_PROBE_SLAVE_HOSTS)
        case CR_PROBE_SLAVE_HOSTS:
            s = @"CR_PROBE_SLAVE_HOSTS";
            break;
#endif

#if defined(CR_PROBE_SLAVE_CONNECT)
        case CR_PROBE_SLAVE_CONNECT:
            s = @"CR_PROBE_SLAVE_CONNECT";
            break;
#endif

#if defined(CR_PROBE_MASTER_CONNECT)
        case CR_PROBE_MASTER_CONNECT:
            s = @"CR_PROBE_MASTER_CONNECT";
            break;
#endif

        case CR_SSL_CONNECTION_ERROR:
            s = @"CR_SSL_CONNECTION_ERROR";
            break;
        case CR_MALFORMED_PACKET:
            s = @"CR_MALFORMED_PACKET";
            break;
#if defined(CR_WRONG_LICENSE)
        case CR_WRONG_LICENSE:
            s = @"CR_WRONG_LICENSE";
            break;
#endif
#if defined(CR_NULL_POINTER)
        case CR_NULL_POINTER:
            s = @"CR_NULL_POINTER";
            break;
#endif

        case CR_NO_PREPARE_STMT:
            s = @"CR_NO_PREPARE_STMT";
            break;
        case CR_PARAMS_NOT_BOUND:
            s = @"CR_PARAMS_NOT_BOUND";
            break;
#if defined(CR_DATA_TRUNCATED)
        case CR_DATA_TRUNCATED:
            s = @"CR_DATA_TRUNCATED";
            break;
#endif

#if defined(CR_NO_PARAMETERS_EXISTS)
        case CR_NO_PARAMETERS_EXISTS:
            s = @"CR_NO_PARAMETERS_EXISTS";
            break;
#endif

        case CR_INVALID_PARAMETER_NO:
            s = @"CR_INVALID_PARAMETER_NO";
            break;
        case CR_INVALID_BUFFER_USE:
            s = @"CR_INVALID_BUFFER_USE";
            break;
        case CR_UNSUPPORTED_PARAM_TYPE:
            s = @"CR_UNSUPPORTED_PARAM_TYPE";
            break;
        case CR_SHARED_MEMORY_CONNECTION:
            s = @"CR_SHARED_MEMORY_CONNECTION";
            break;

#if defined(CR_SHARED_MEMORY_CONNECT_REQUEST_ERROR)
        case CR_SHARED_MEMORY_CONNECT_REQUEST_ERROR:
            s = @"CR_SHARED_MEMORY_CONNECT_REQUEST_ERROR";
            break;
#endif

#if defined(CR_SHARED_MEMORY_CONNECT_ANSWER_ERROR)
        case CR_SHARED_MEMORY_CONNECT_ANSWER_ERROR:
            s = @"CR_SHARED_MEMORY_CONNECT_ANSWER_ERROR";
            break;
#endif

#if defined(CR_SHARED_MEMORY_CONNECT_FILE_MAP_ERROR)
        case CR_SHARED_MEMORY_CONNECT_FILE_MAP_ERROR:
            s = @"CR_SHARED_MEMORY_CONNECT_FILE_MAP_ERROR";
            break;
#endif

#if defined(CR_SHARED_MEMORY_CONNECT_MAP_ERROR)
        case CR_SHARED_MEMORY_CONNECT_MAP_ERROR:
            s = @"CR_SHARED_MEMORY_CONNECT_MAP_ERROR";
            break;
#endif

#if defined(CR_SHARED_MEMORY_FILE_MAP_ERROR)
        case CR_SHARED_MEMORY_FILE_MAP_ERROR:
            s = @"CR_SHARED_MEMORY_FILE_MAP_ERROR";
            break;
#endif

#if defined(CR_SHARED_MEMORY_MAP_ERROR)
        case CR_SHARED_MEMORY_MAP_ERROR:
            s = @"CR_SHARED_MEMORY_MAP_ERROR";
            break;
#endif

#if defined(CR_SHARED_MEMORY_EVENT_ERROR)
        case CR_SHARED_MEMORY_EVENT_ERROR:
            s = @"CR_SHARED_MEMORY_EVENT_ERROR";
            break;
#endif

#if defined(CR_SHARED_MEMORY_CONNECT_ABANDONED_ERROR)
        case CR_SHARED_MEMORY_CONNECT_ABANDONED_ERROR:
            s = @"CR_SHARED_MEMORY_CONNECT_ABANDONED_ERROR";
            break;
#endif

#if defined(CR_SHARED_MEMORY_CONNECT_SET_ERROR)
        case CR_SHARED_MEMORY_CONNECT_SET_ERROR:
            s = @"CR_SHARED_MEMORY_CONNECT_SET_ERROR";
            break;
#endif

#if defined(CR_CONN_UNKNOW_PROTOCOL)
        case CR_CONN_UNKNOW_PROTOCOL:
            s = @"CR_CONN_UNKNOW_PROTOCOL";
            break;
#endif
#if defined(CR_INVALID_CONN_HANDLE)
        case CR_INVALID_CONN_HANDLE:
            s = @"CR_INVALID_CONN_HANDLE";
            break;
#endif
#if defined(CR_SECURE_AUTH)
        case CR_SECURE_AUTH:
            s = @"CR_SECURE_AUTH";
            break;
#endif

#if defined(CR_FETCH_CANCELED)
        case CR_FETCH_CANCELED:
            s = @"CR_FETCH_CANCELED";
            break;
#endif

        case CR_NO_DATA:
            s = @"CR_NO_DATA";
            break;
        case CR_NO_STMT_METADATA:
            s = @"CR_NO_STMT_METADATA";
            break;
#if defined(CR_NO_RESULT_SET)
        case CR_NO_RESULT_SET:
            s = @"CR_NO_RESULT_SET";
            break;
#endif
        case CR_NOT_IMPLEMENTED:
            s = @"CR_NOT_IMPLEMENTED";
            break;
        case CR_SERVER_LOST_EXTENDED:
            s = @"CR_SERVER_LOST_EXTENDED";
            break;
        case CR_STMT_CLOSED:
            s = @"CR_STMT_CLOSED";
            break;
        case CR_NEW_STMT_METADATA:
            s = @"CR_NEW_STMT_METADATA";
            break;
#ifdef CR_ALREADY_CONNECTED
        case CR_ALREADY_CONNECTED:
            s = @"CR_ALREADY_CONNECTED";
            break;
#endif

#ifdef CR_AUTH_PLUGIN_CANNOT_LOAD
        case CR_AUTH_PLUGIN_CANNOT_LOAD:
            s = @"CR_AUTH_PLUGIN_CANNOT_LOAD";
            break;
#endif
    }
    if(s)
    {
        s = [NSString stringWithFormat:@"MYSQL: %@\n",s];
        [self.logFeed debug:0 inSubsection:@"mysql" withText:s];
        NSLog(@"%@",s);
    }
    return state;
#endif
}


- (BOOL)queryWithNoResult:(NSString *)sql allowFail:(BOOL)allowFail affectedRows:(unsigned long long *)count
{
#if !defined(HAVE_MYSQL)
    return NO;
#else
    @autoreleasepool
    {
        BOOL success = YES;
#ifdef MYSQL_DEBUG
        NSLog(@"SQL: %@",sql);
#endif
        sql = [sql stringByTrimmingCharactersInSet:[UMObject whitespaceAndNewlineCharacterSet]];
        if([sql length]==0)
        {
            return YES;
        }
        [self.logFeed debug:0 inSubsection:@"mysql" withText:[NSString stringWithFormat:@"MYSQL_QUERY: *** %s***\n\n",[sql UTF8String]]];
        
        self.lastInProgress = [[UMDbMySqlInProgress alloc]initWithString:sql previousQuery:lastInProgress];
        
        int state = mysql_query(connection,[sql UTF8String]);
        
        MYSQL_RES *r = mysql_store_result(connection);
        if(r)
        {
            mysql_free_result(r);
            NSString *s = [NSString stringWithFormat:@"we are getting a result while we are not expecting one\nQuery: %@",sql];
            fprintf(stderr,"ERROR: %s",s.UTF8String);// [NSException exceptionWithName:@"NSObjectInaccessibleException" reason:s userInfo:nil];
        }
        [lastInProgress completed];
        [self errorCheck:state forSql:sql];
        if(state==0)
        {
            /*success */
            if(count!=NULL)
            {
                *count = (unsigned long long) mysql_affected_rows(connection);
            }
        }
        [self.logFeed debug:0 inSubsection:@"mysql" withText:[NSString stringWithFormat:@"STATE: %d\n\n",state]];
        
        if(state != 0)
        {
            success = NO;
            
            if(!allowFail)
            {
                NSString *sql_error = @(mysql_error(connection));
                NSString *reason = [NSString stringWithFormat:@"query failed, sql = %s, error=%@",[sql UTF8String],sql_error];
                @throw [NSException exceptionWithName:@"NSObjectInaccessibleException" reason:reason userInfo:nil];
            }
            else
            {
                self.lastInsertId = @(mysql_insert_id(connection));
#if (ULIBDB_CONFIG==Debug)
                [self.logFeed majorError:0 withText:[NSString stringWithFormat:@"query failed, sql = \"%@\", error=%s",sql,mysql_error(connection)]];
#endif
                ;
            }
        }
#ifdef MYSQL_DEBUG
        if(success)
        {
            [self.logFeed debug:0 inSubsection:@"mysql" withText:@"==SUCCESS=="];
        }
        else
        {
            [self.logFeed debug:0 inSubsection:@"mysql" withText:@"==FAILURE=="];
        }
#endif
        return success;
    }
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
#if !defined(HAVE_MYSQL)
    return NULL;
#else
    @autoreleasepool
    {
        
        UMDbResult* result = NULL;
        MYSQL_RES *r = NULL;
#ifdef MYSQL_DEBUG
        NSLog(@"SQL: %@",sql);
#endif
        if([sql length]==0)
        {
            return NULL;
        }
        
        self.lastInProgress = [[UMDbMySqlInProgress alloc]initWithString:sql previousQuery:lastInProgress];
        int state = mysql_query(connection,[sql UTF8String]);
        r = mysql_store_result(connection);
        
        [lastInProgress completed];
        [self errorCheck:state forSql:sql];
        if(state != 0)
        {
            if(failPermission)
            {
#if (ULIBDB_CONFIG==Debug)
                [self.logFeed minorError:0 withText:[NSString stringWithFormat:@"query failed, sql = %s, error=%s",[sql UTF8String],mysql_error(connection)]]
#endif
                ;
            }
            else
            {
                NSString *reason = [NSString stringWithFormat:@"query failed, sql = %s, error=%s",[sql UTF8String],mysql_error(connection)];
                @throw [NSException exceptionWithName:@"NSObjectNotAvailableException" reason:reason userInfo:nil];
            }
            return NULL;
        }
        
        
        if(r==NULL)
        {
            NSString *reason = [NSString stringWithFormat:@"mysql_store_result() failed, sql = %s, error=%s",[sql UTF8String],mysql_error(connection)];
            @throw [NSException exceptionWithName:@"NSObjectNotAvailableException" reason:reason userInfo:nil];
        }
        my_ulonglong affected = mysql_affected_rows(connection);
        if(file)
        {
            result = [[UMDbResult alloc]initForFile:file line:line];
        }
        else
        {
            result = [[UMDbResult alloc]init];
        }
        result.affectedRows=affected;
        MYSQL_FIELD *field;
        long i = 0;
        while((field = mysql_fetch_field(r)))
        {
            NSString *ourName = @(field->name);
            [result setColumName:ourName forIndex:i];
            [result setColumType:@(field->type) forIndex:i];
            [result setColumCharset:@(field->charsetnr) forIndex:i];
            ++i;
        }
        
        if(r && affected > 0)
        {
            long columnsCount = mysql_num_fields(r);
            MYSQL_ROW row;
            while((row = mysql_fetch_row(r)))
            {
                unsigned long *lengths;
                lengths = mysql_fetch_lengths(r);
                
                NSMutableArray *arr = [[NSMutableArray alloc]init];
                for(long i=0;i<columnsCount;i++)
                {
                    id value = [NSNull null];
                    char *cstr = row[i];
                    NSNumber *n = [result columTypeForIndex:i];
                    NSNumber *cs = [result columCharsetForIndex:i];
                    if(n)
                    {
                        NSData *data = NULL;
                        if(cstr != NULL)
                        {
                             data = [NSData dataWithBytes:cstr length:lengths[i]];
                        }
                        switch(n.intValue)
                        {
                            case MYSQL_TYPE_NULL:
                                break;
                            case MYSQL_TYPE_BLOB:
                            case MYSQL_TYPE_TINY_BLOB:
                            case MYSQL_TYPE_MEDIUM_BLOB:
                            case MYSQL_TYPE_LONG_BLOB:
                                /* https://dev.mysql.com/doc/c-api/8.0/en/c-api-data-structures.html
                                 says:
                                 To distinguish between binary and nonbinary data for string data types,
                                 check whether the charsetnr value is 63. If so, the character set is binary,
                                 which indicates binary rather than nonbinary data. This enables you to
                                 distinguish BINARY from CHAR, VARBINARY from VARCHAR, and the BLOB types
                                 from the TEXT types.
                                 */

                                if(cs.intValue==63) /* its a BLOB */
                                {
                                    value = data;
                                }
                                else
                                {
                                    value = [data stringValue];
                                }
                                break;
                            default:
                                /* we return everything as strings except for BLOB's */
                                value = [data stringValue];
                                break;
                        }
                        if(value==NULL)
                        {
                            value = [NSNull null];
                        }
                    }
                    [arr addObject:value];
                }
                [result addRow:arr];
            }
        }
        if(r)
        {
            mysql_free_result(r);
        }
        return result;
    }
#endif
}

- (BOOL) ping
{
#if !defined(HAVE_MYSQL)
    return YES;
#else
    @autoreleasepool
    {
        if(sessionStatus != UMDBSESSION_STATUS_CONNECTED)
        {
            return YES;
        }
    
        long state;
        ummutex_lock(_sessionLock);
        @try
        {
            self.lastInProgress = [[UMDbMySqlInProgress alloc]initWithCString:"ping" previousQuery:lastInProgress];
            state = mysql_ping(connection);
            [lastInProgress completed];
            if (state)
            {
                [self.logFeed debug:0 inSubsection:@"mysql" withText:[NSString stringWithFormat:@"mysql_error [%s] while executing ping",mysql_error(connection)]];
                return NO;
            }
        }
        @finally
        {
            ummutex_unlock(_sessionLock);
        }
        return YES;
    }
#endif
}

- (char)fieldQuoteChar
{
    return '`';
}

- (NSDictionary *)explainTable:(NSString *)table
{
    @autoreleasepool
    {
        NSString *sql = [NSString stringWithFormat:@"explain `%@`",table];
        UMDbResult *result = [self queryWithMultipleRowsResult:sql allowFail:YES];

        NSArray *fieldNames = [result columNames];
        int rownum = 0;
        NSArray *row = [result fetchRow];
        rownum++;
        NSMutableDictionary *fieldDefinitions = [[NSMutableDictionary alloc]init];
        while(row)
        {
            NSMutableDictionary *entry = [[NSMutableDictionary alloc]init];
            entry[@"pos"]=[NSNumber numberWithInt:rownum];
            for(int i=0;i< result.columsCount;i++)
            {
                NSString *n = fieldNames[i];
                NSString *v = row[i];
                if([n isEqualToString:@"Field"])
                {
                    fieldDefinitions[v]=entry;
                }
                entry[n]=v;
            }
            row = [result fetchRow];
            rownum++;
        }
        return fieldDefinitions;
    }
}

- (NSString *)sqlEscapeString:(NSString *)in
{
#if !defined(HAVE_MYSQL)
    return [super sqlEscapeString:in];
#else
    NSData *d = [in dataUsingEncoding:NSUTF8StringEncoding];
    const char *from = d.bytes;
    size_t len = d.length * 2 + 16;
    char *to   = malloc(len);
    if(to)
    {
        memset(to,0x00,len);
        mysql_real_escape_string(connection, to, from, d.length);
        NSString *result = @(to);
        free(to);
        return result;
    }
    return NULL;
#endif
}

@end


