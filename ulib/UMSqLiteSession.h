//
//  UMSqLiteSession.h
//  ulibdb.framework
//
//  Created by Andreas Fink on 25.10.11.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.

#import <ulib/UMDbSession.h>

#ifdef HAVE_SQLITE

@interface UMSqLiteSession : UMDbSession
{
    int i; 
}

- (UMSqLiteSession *)initWithPool:(UMDbPool *)dbpool;
@end

#endif
