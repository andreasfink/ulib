//
//  UMSctpTask_Open.m
//  ulib
//
//  Created by Andreas Fink on 29.11.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#if defined(HAVE_SCTP_SCTP_H) || defined(HAVE_NETINET_SCTP_H)

#import <ulib/UMSctpTask_Open.h>
#import "UMLayerSctp.h"

#include <sys/errno.h>
#include <unistd.h>
#include <sys/types.h>

#import "ulibsctp_config.h"

#ifdef HAVE_SCTP_SCTP_H
#import <sctp/sctp.h>
#endif

#ifdef HAVE_NETINET_SCTP_H
#include "netinet/sctp.h"
#endif

#include <arpa/inet.h>

@implementation UMSctpTask_Open


- (UMSctpTask_Open *)initWithReceiver:(UMLayer *)rx sender:(id<UMLayerSctpUserProtocol>)tx
{
    self = [super initWithName:[[self class]description]
                      receiver:rx
                        sender:tx
       requiresSynchronisation:NO];
    if(self)
    {
        self.name = @"UMSctpTask_Open";

    }
    return self;
}

- (void)main
{
    @autoreleasepool
    {
        UMLayerSctp *link = (UMLayerSctp *)self.receiver;
        [link _openTask:self];
    }
}

@end
#endif
