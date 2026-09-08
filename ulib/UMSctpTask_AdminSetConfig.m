//
//  UMSctpTask_AdminSetConfig.m
//  ulib
//
//  Created by Andreas Fink on 01.12.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//


#import <ulib/UMSctpTask_AdminSetConfig.h>
#import <ulib/UMLayerSctp.h>

@implementation UMSctpTask_AdminSetConfig

@synthesize config;

- (UMSctpTask_AdminSetConfig *)initWithReceiver:(UMLayerSctp *)rx
                                         config:(NSDictionary *)cfg
                             applicationContext:(id)app
{
    self = [super initWithName:[[self class]description]
                      receiver:rx
                        sender:NULL
       requiresSynchronisation:NO];
    if(self)
    {
        self.name = @"UMSctpTask_AdminSetConfig";
        self.config = cfg;
        appContext = app;
    }
    return self;
}

- (void)main
{
    @autoreleasepool
    {
        UMLayerSctp *link = (UMLayerSctp *)self.receiver;
        [link _adminSetConfigTask:self];
    }
}

-(id) appContext
{
    return appContext;
}

@end
