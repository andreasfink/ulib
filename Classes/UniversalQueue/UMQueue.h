//
//  UMQueue.h
//  thread safe generic Fifo queue
//  ulib.framework
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.

#import "UMObject.h"
@class UMMutex;

/*!
 @class UMQueue
 @brief A UMQueue is a queue where you can stuff things into and pull stuff from it.
  it is synchronized and thus save to use multithreaded (unless created with initWithoutLock)
 */


@interface UMQueue : UMObject
{
@private
    NSMutableArray  *queue;
    UMMutex          *_lock;
}

- (UMQueue *)init;
- (UMQueue *)initWithoutLock;
- (void)append:(id)obj;
- (void)appendUnique:(id)obj;
- (id)getFirst;
- (id)getFirstWhileLocked;
- (void)insertFirst:(id)obj;
- (NSInteger)count;
- (void)removeObject:(id)object;

@end
