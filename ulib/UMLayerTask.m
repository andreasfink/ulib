//
//  UMLayerTask.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMLayerTask.h>
#import <ulib/UMLayer.h>
#import <ulib/UMThroughputCounter.h>
#import <ulib/UMLogFeed.h>

@implementation UMLayerTask

@synthesize receiver;
@synthesize sender;
@synthesize requiresSynchronisation;


- (UMLayerTask *)initWithName:(NSString *)n
                     receiver:(UMLayer *)rx
                       sender:(id<UMLayerUserProtocol>)tx
      requiresSynchronisation:(BOOL)reqsync
{

    if(rx==NULL)
    {
        NSAssert(rx != NULL,@"receiver can not be NULL");
    }
    if(n==NULL)
    {
        n = [[self class]description];
    }
    self = [super initWithName:n];
    if(self)
    {
        self.receiver = rx;
        self.sender = tx;
        self.requiresSynchronisation = reqsync;
    }
    return self;
}

- (UMLayerTask *)initWithName:(NSString *)n receiver:(UMLayer *)rx sender:(id<UMLayerUserProtocol>)tx;
{
    return [self initWithName:n receiver:rx sender:tx requiresSynchronisation:NO];
}

- (void)runOnBackgrounder:(UMBackgrounder *)bg
{
    @autoreleasepool
    {
        if(receiver.logLevel <= UMLOG_DEBUG)
        {
            NSString *s = self.name;
            [receiver.logFeed debug:0 inSubsection:@"exec" withText:s];
        }
        if(requiresSynchronisation)
        {
            @synchronized(receiver)
            {
                [super runOnBackgrounder:bg];
            }
        }
        else
        {
            [super runOnBackgrounder:bg];
        }
    }
}

@end
