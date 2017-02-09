//
//  UMTimer.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import "UMTimer.h"
#import "UMThroughputCounter.h"
#import "UMTimerBackgrounder.h"
#import "UMBackgrounder.h"
#include <time.h>
@implementation UMTimer

@synthesize isRunning;
@synthesize startTime;
@synthesize lastChecked;
@synthesize expiryTime;
@synthesize duration;
@synthesize name;

@synthesize objectToCall;
@synthesize selectorToCall;
@synthesize parameter;

- (UMTimer *)initWithTarget:(id)target selector:(SEL)selector
{
    return [self initWithTarget:target selector:selector object:NULL duration:0 name:NULL repeats:NO];
}

- (UMTimer *)initWithTarget:(id)target selector:(SEL)selector object:(id)object duration:(UMMicroSec)dur name:(NSString *)n repeats:(BOOL)r;
{
    self =[super init];
    if(self)
    {
        UMMicroSec now  = [UMThroughputCounter microsecondTime];
        isRunning = NO;
        startTime = now;
        lastChecked = now;
        expiryTime = 0;
        duration = dur;
        name = @"";
        objectToCall = target;
        selectorToCall = selector;
        parameter = object;
        name = n;
        repeats = r;
    }
    return self;
}


- (void)start
{
    @synchronized(self)
    {
        self.isRunning = YES;
        UMMicroSec now  = [UMThroughputCounter microsecondTime];
        expiryTime = now + duration;
        [[UMTimerBackgrounder sharedInstance]addTimer:self];
    }

}

- (void) stop
{
    @synchronized(self)
    {
        self.isRunning = NO;
        expiryTime = 0;
        [[UMTimerBackgrounder sharedInstance]removeTimer:self];
    }
}

- (BOOL)isExpired
{
    UMMicroSec now  = [UMThroughputCounter microsecondTime];
    return [self isExpired:now];
}

- (BOOL)isExpired:(UMMicroSec)now
{
    @synchronized(self)
    {
        lastChecked = now;
        if(now > expiryTime)
        {
            return YES;
        }
    }
    return NO;
}


- (UMMicroSec)timeLeft:(UMMicroSec)now
{
    @synchronized(self)
    {
        return expiryTime - now;
    }
}

- (void)fire
{
    /* we issue the callback */
    if(repeats)
    {
        [self start];
    }
    else
    {
        [self stop];
    }
    [objectToCall runSelectorInBackground:selectorToCall withObject:parameter];
}

@end
