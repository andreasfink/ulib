//
//  UMQueueSingle.h
//  thread safe generic Fifo queue
//  ulib.framework
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.

#import <ulib/UMObject.h>
@class UMMutex;

/*!
 @class UMSingleQueue
 @brief A UMSingleQueue is a queue where you can stuff things into and pull stuff from it.
  it is synchronized and thus save to use multithreaded (unless created with initWithoutLock)
 */


@interface UMQueueSingle : UMObject
{
    UMMutex          *_queueLock;
    NSMutableArray   *_queue;
}

@property(readwrite,strong,atomic) NSMutableArray *queue;

- (UMQueueSingle *)init;
- (UMQueueSingle *)initWithoutLock;
- (void)append:(id)obj;
- (void)appendUnique:(id)obj;
- (id)getFirst;
- (id)peekFirst; /* access first entry without removing it */
- (id)getFirstWhileLocked;
- (void)insertFirst:(id)obj;
- (NSInteger)count;
- (void)removeObject:(id)object;
- (void)lock;
- (id)getObjectAtIndex:(NSInteger)i;
- (void)unlock;

@end
