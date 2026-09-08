//
//  UMSctpTask_AdminDetach.m
//  ulib
//
//  Created by Andreas Fink on 02.12.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#if defined(HAVE_SCTP_SCTP_H) || defined(HAVE_NETINET_SCTP_H)

#import <ulib/UMSctpTask_AdminDetach.h>
#import <ulib/UMLayerSctp.h>

@implementation UMSctpTask_AdminDetach
@synthesize userId;

- (UMSctpTask_AdminDetach *)initWithReceiver:(UMLayerSctp *)rx
                                      sender:(id<UMLayerSctpUserProtocol>)tx
                                      userId:(id)uid;
{
    self = [super initWithName:[[self class]description]
                      receiver:rx
                        sender:tx
       requiresSynchronisation:NO];
    if(self)
    {
        self.name = @"UMSctpTask_AdminDetach";
        self.userId     = uid;
    }
    return self;
}

- (void)main
{
    @autoreleasepool
    {
        UMLayerSctp *link = (UMLayerSctp *)self.receiver;
        [link _adminDetachTask:self];
    }
}

@end
#endif
