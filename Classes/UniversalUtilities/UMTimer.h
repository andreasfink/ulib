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
    BOOL                isRunning;
    UMMicroSec          startTime;
    UMMicroSec          lastChecked;
    UMMicroSec          expiryTime;
    UMMicroSec          duration;
    NSString            *name;
    BOOL                repeats;
    
    UMObject            *__weak objectToCall;
    SEL                 selectorToCall;
    id                  parameter;
}

@property(readwrite,assign) BOOL                isRunning;
@property(readwrite,assign) UMMicroSec          startTime;
@property(readwrite,assign) UMMicroSec          lastChecked;
@property(readwrite,assign) UMMicroSec          expiryTime;
@property(readwrite,assign) UMMicroSec          duration;
@property(readwrite,strong) NSString            *name;

@property(readwrite,weak)   UMObject            *objectToCall;
@property(readwrite,assign) SEL                 selectorToCall;
@property(readwrite,strong) id                  parameter;

- (UMTimer *)initWithTarget:(id)target selector:(SEL)selector object:(id)object duration:(UMMicroSec)dur name:(NSString *)n repeats:(BOOL)rep;
- (UMTimer *)initWithTarget:(id)target selector:(SEL)selector;

- (BOOL)isRunning;
- (BOOL)isExpired;
- (BOOL)isExpired:(UMMicroSec)now;
- (UMMicroSec)timeLeft:(UMMicroSec)now;

- (void)start;
- (void)stop;
- (void)fire;


@end
