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

- (UMTimer *)initWithTarget:(id)target selector:(SEL)selector
{
    return [self initWithTarget:target
                       selector:selector
                         object:NULL
                       duration:0
                           name:NULL
                        repeats:NO];
}

- (UMTimer *)initWithTarget:(id)target
                   selector:(SEL)selector
                     object:(id)object
                   duration:(UMMicroSec)dur
                       name:(NSString *)n
                    repeats:(BOOL)r;
{
    self =[super init];
    if(self)
    {
        UMMicroSec now  = [UMThroughputCounter microsecondTime];
        _isRunning = NO;
        _startTime = now;
        _lastChecked = now;
        _expiryTime = 0;
        _duration = dur;
        _objectToCall = target;
        _selectorToCall = selector;
        _parameter = object;
        _name = n;
        _repeats = r;
    }
    return self;
}


- (void)start
{
    self.isRunning = YES;
    UMMicroSec now  = [UMThroughputCounter microsecondTime];
    self.expiryTime = now + self.duration;
    [[UMTimerBackgrounder sharedInstance]addTimer:self];
}

- (void) stop
{
    self.isRunning = NO;
    self.expiryTime = 0;
    [[UMTimerBackgrounder sharedInstance]removeTimer:self];
}

- (BOOL)isExpired
{
    UMMicroSec now  = [UMThroughputCounter microsecondTime];
    return [self isExpired:now];
}

- (BOOL)isExpired:(UMMicroSec)now
{
    self.lastChecked = now;
    if(now > self.expiryTime)
    {
        return YES;
    }
    return NO;
}


- (UMMicroSec)timeLeft:(UMMicroSec)now
{
    return self.expiryTime - now;
}

- (void)fire
{
    /* we issue the callback */
    if(self.repeats)
    {
        [self start];
    }
    else
    {
        [self stop];
    }
    [self.objectToCall runSelectorInBackground:self.selectorToCall withObject:self.parameter];
}

@end
