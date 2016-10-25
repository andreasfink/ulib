//
//  UMLogLevel.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//
//

#import <Foundation/Foundation.h>

typedef enum UMLogLevel
{
    UMLOG_DEBUG		= 0,
    UMLOG_INFO		= 1,
    UMLOG_WARNING	= 2,
    UMLOG_MINOR		= 3,
    UMLOG_MAJOR		= 4,
    UMLOG_PANIC		= 5,
} UMLogLevel;

NSString *ulib_loglevel_string(UMLogLevel level);
