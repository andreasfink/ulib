//
//  UMLayerTask.m
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#import "UMLayerTask.h"
#import "UMLayer.h"
#import "UMThroughputCounter.h"
#import "UMLogFeed.h"

@implementation UMLayerTask

@synthesize receiver;
@synthesize sender;
@synthesize requiresSynchronisation;


- (UMLayerTask *)initWithName:(NSString *)n
                     receiver:(UMLayer *)rx
                       sender:(id<UMLayerUserProtocol>)tx
      requiresSynchronisation:(BOOL)reqsync
{

    NSAssert(rx != NULL,@"receiver can not be NULL");

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
        [receiver.logFeed debug:0 inSubsection:@"exec" withText:self.name];
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
