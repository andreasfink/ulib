//
//  ulib.m
//  ulib
//
//  Created by Andreas Fink on 10/05/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>
#include "../version.h"

#ifdef HAVE_MYSQL
#import <mariadb/mysql.h>
#endif

NSString *ulib_version(void)
{
    return @(VERSION);
}

NSString *ulib_build(void)
{
    return @(BUILD);
}

NSString *ulib_builddate(void)
{
    return @(BUILDDATE);
}

NSString *ulib_compiledate(void)
{
    return @(COMPILEDATE);
}


void ulibdb_startup(void)
{
#ifdef HAVE_MYSQL
    if (mysql_library_init(0, NULL, NULL))
    {
        fprintf(stderr,"could not initialize MySQL library");
        exit(1);
    }
    if( mysql_thread_safe() == 0)
    {
        @throw ([NSException exceptionWithName:@"ulibdb" reason:@"mysql library is not thread safe" userInfo:NULL]);
    }
#endif
}

void ulibdb_shutdown(void)
{
#ifdef HAVE_MYSQL
    mysql_library_end();
#endif
}


void ulibdb_thread_init(void)
{
#ifdef HAVE_MYSQL
    mysql_thread_init();
#endif
}

void ulibdb_thread_exit(void)
{
#ifdef HAVE_MYSQL
    mysql_thread_end();
#endif
}
