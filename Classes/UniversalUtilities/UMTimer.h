//
//  UMTimer.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import "UMObject.h"
#import "UMMicroSec.h"
@class UMMutex;
/* all timers are in microseconds since Jan. 1, 1970 */

@interface UMTimer : UMObject
{
    BOOL                _isRunning;
    UMMicroSec          _startTime;
    UMMicroSec          _lastChecked;
    UMMicroSec          _expiryTime;
    UMMicroSec          _microsecDuration;
    NSString            *_name;
    BOOL                _repeats;
    UMObject            *_objectToCall;
    SEL                 _selectorToCall;
    id                  _parameter;
    UMMutex             *_timerMutex;
    BOOL                _runCallbackInForeground;
}

@property(readwrite,assign,atomic) BOOL                isRunning;
@property(readwrite,assign,atomic) UMMicroSec          startTime;
@property(readwrite,assign,atomic) UMMicroSec          lastChecked;
@property(readwrite,assign,atomic) UMMicroSec          expiryTime;
@property(readwrite,assign,atomic) UMMicroSec          microsecDuration;
@property(readwrite,strong,atomic) NSString            *name;
@property(readwrite,assign,atomic) BOOL                repeats;
@property(readwrite,assign,atomic) BOOL                runCallbackInForeground;
@property(readwrite,strong)                            UMObject *objectToCall;
@property(readwrite,assign,atomic) SEL                 selectorToCall;
@property(readwrite,strong,atomic) id                  parameter;

- (UMTimer *)initWithTarget:(id)target
                   selector:(SEL)selector
                     object:(id)object
                    seconds:(NSTimeInterval)d
                       name:(NSString *)n
                    repeats:(BOOL)r
            runInForeground:(BOOL)inForeground;

- (UMTimer *)initWithTarget:(id)target
                   selector:(SEL)selector
                     object:(id)object
                    seconds:(NSTimeInterval)d
                       name:(NSString *)n
                    repeats:(BOOL)r;

- (UMTimer *)initWithTarget:(id)target
                   selector:(SEL)selector;

- (BOOL)isExpired;
- (BOOL)isExpired:(UMMicroSec)now;
- (UMMicroSec)timeLeft:(UMMicroSec)now;

- (void)start;
- (void)startIfNotRunning;
- (void)stop;
- (void)fire;
- (void)setSeconds:(NSTimeInterval)sec;
- (NSTimeInterval)seconds;


@end
