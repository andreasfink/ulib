//
//  UMTimerBackgrounder.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import "UMBackgrounder.h"

@class UMTimer;

@interface UMTimerBackgrounder : UMBackgrounder
{
    NSMutableArray *timers;
}

- (void)addTimer:(UMTimer *)t;
- (void)removeTimer:(UMTimer *)t;
+ (UMTimerBackgrounder *)sharedInstance;

@end
