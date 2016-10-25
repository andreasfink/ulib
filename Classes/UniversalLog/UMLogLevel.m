//
//  UMLogLevel.m
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//
//

#import "UMLogLevel.h"

NSString *ulib_loglevel_string(UMLogLevel level)
{
    switch(level)
    {
        case UMLOG_DEBUG:
            return @"DEBUG";
        case UMLOG_INFO:
            return @"INFO";
        case UMLOG_WARNING:
            return @"WARNING";
        case UMLOG_MINOR:
            return @"MINOR";
        case UMLOG_MAJOR:
            return @"MAJOR";
        case UMLOG_PANIC:
            return @"PANIC";
        default:
            return [NSString stringWithFormat:@"LogLevel %d",(int)level];

    }
}
