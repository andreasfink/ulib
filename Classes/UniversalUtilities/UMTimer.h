//
//  UMTimer.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import "UMObject.h"
#import "UMMicroSec.h"

/* all timers are in microseconds since Jan. 1, 1970 */

@interface UMTimer : UMObject
{
    BOOL                _isRunning;
    UMMicroSec          _startTime;
    UMMicroSec          _lastChecked;
    UMMicroSec          _expiryTime;
    UMMicroSec          _duration;
    NSString            *_name;
    BOOL                _repeats;
    
    UMObject            *__weak _objectToCall;
    SEL                 _selectorToCall;
    id                  _parameter;
}

@property(readwrite,assign,atomic) BOOL                isRunning;
@property(readwrite,assign,atomic) UMMicroSec          startTime;
@property(readwrite,assign,atomic) UMMicroSec          lastChecked;
@property(readwrite,assign,atomic) UMMicroSec          expiryTime;
@property(readwrite,assign,atomic) UMMicroSec          duration;
@property(readwrite,strong,atomic) NSString            *name;
@property(readwrite,assign,atomic) BOOL                repeats;


@property(readwrite,weak)   UMObject            *objectToCall;
@property(readwrite,assign,atomic) SEL                 selectorToCall;
@property(readwrite,strong,atomic) id                  parameter;

- (UMTimer *)initWithTarget:(id)target
                   selector:(SEL)selector
                     object:(id)object
                   duration:(UMMicroSec)dur
                       name:(NSString *)n repeats:(BOOL)rep;

- (UMTimer *)initWithTarget:(id)target
                   selector:(SEL)selector;

- (BOOL)isExpired;
- (BOOL)isExpired:(UMMicroSec)now;
- (UMMicroSec)timeLeft:(UMMicroSec)now;

- (void)start;
- (void)stop;
- (void)fire;


@end
