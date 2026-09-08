//
//  UMSctpTask_Open.m
//  ulib
//
//  Created by Andreas Fink on 29.11.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//


#import <ulib/UMSctpTask_Open.h>
#import <ulib/UMLayerSctp.h>

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
