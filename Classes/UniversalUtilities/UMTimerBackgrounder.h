//
//  UMTimerBackgrounder.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
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
+(UMTimerBackgrounder *)sharedInstance;

@end
