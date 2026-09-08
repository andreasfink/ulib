//
//  UMSctpTask_Close.m
//  ulib
//
//  Created by Andreas Fink on 29.11.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#if defined(HAVE_SCTP_SCTP_H) || defined(HAVE_NETINET_SCTP_H)

#import <ulib/UMSctpTask_Close.h>
#import <ulib/UMLayerSctp.h>

@implementation UMSctpTask_Close


- (UMSctpTask_Close *)initWithReceiver:(UMLayer *)rx sender:(id<UMLayerSctpUserProtocol>)tx
{
    self = [super initWithName:[[self class]description]
                      receiver:rx
                        sender:tx
       requiresSynchronisation:NO];
    if(self)
    {
        self.name = @"UMSctpTask_Close";
    }
    return self;
}

- (void)main
{
    @autoreleasepool
    {
        UMLayerSctp *link = (UMLayerSctp *)self.receiver;
        [link _closeTask:self];
    }
}

@end
#endif
