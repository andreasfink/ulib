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
#import "UMMutex.h"

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
                    seconds:(NSTimeInterval)d
                       name:(NSString *)n
                    repeats:(BOOL)r
{
    self =[super init];
    if(self)
    {
        UMMicroSec now  = [UMThroughputCounter microsecondTime];
        _isRunning = NO;
        _startTime = now;
        _lastChecked = now;
        _expiryTime = 0;
        _duration = (UMMicroSec)(d * 1000000.0);
        _objectToCall = target;
        _selectorToCall = selector;
        _parameter = object;
        _name = n;
        _repeats = r;
        _timerMutex = [[UMMutex alloc]initWithName:[NSString stringWithFormat:@"timer %@",n]];

    }
    return self;
    return [self initWithTarget:target
                       selector:selector
                         object:(id)object
                       duration:(UMMicroSec)(d * 1000000.0)
                           name:n
                        repeats:r];
}


- (void)setSeconds:(NSTimeInterval)sec
{
    [_timerMutex lock];
    _duration = (UMMicroSec)(sec * 1000000.0);
    [_timerMutex unlock];

}
- (NSTimeInterval)seconds
{
    NSTimeInterval sec;
    [_timerMutex lock];
    sec = ((double)_duration)/1000000.0;
    [_timerMutex unlock];
    return sec;
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
        _timerMutex = [[UMMutex alloc]initWithName:[NSString stringWithFormat:@"timer %@",n]];

    }
    return self;
}


- (void)startIfNotRunning
{
    [_timerMutex lock];
    if(self.isRunning==NO)
    {
        [self unlockedStart];
    }
    [_timerMutex unlock];
}

- (void)start
{
    [_timerMutex lock];
    [self unlockedStart];
    [_timerMutex unlock];
}

- (void)unlockedStart
{
    if(self.duration<=0)
    {
        NSLog(@"Timer is null seconds %@",self.name);
    }
    NSAssert(self.duration>0,@"Timer is 0");
    if(self.duration < 100)
    {
        NSLog(@"Warning: Starting timer %@ with very short duration %lld µs",self.name,(long long)self.duration);
    }
    self.isRunning = YES;
    UMMicroSec now  = [UMThroughputCounter microsecondTime];
    self.expiryTime = now + self.duration;
    [[UMTimerBackgrounder sharedInstance]addTimer:self];
}

- (void) stop
{
    [_timerMutex lock];
    [self unlockedStop];
    [_timerMutex unlock];
}

- (void) unlockedStop
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
    if(_repeats)
    {
        [self start];
    }
    else
    {
        [self stop];
    }
    if(_runCallbackInForeground)
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [_objectToCall performSelector:_selectorToCall withObject:_parameter];
#pragma clang diagnostic pop
    }
    else
    {
        [_objectToCall runSelectorInBackground:_selectorToCall withObject:_parameter];
    }
}

@end
