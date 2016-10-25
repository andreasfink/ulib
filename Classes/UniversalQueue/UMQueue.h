//
//  UMQueue.h
//  thread safe generic Fifo queue
//  ulib.framework
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.

#import "UMObject.h"
@class UMLock;

@interface UMQueue : UMObject
{
@private
    NSMutableArray  *queue;
    UMLock          *lock;
}

- (UMQueue *)init;
- (UMQueue *)initWithoutLock;
- (void)append:(id)obj;
- (void)appendUnique:(id)obj;
- (id)getFirst;
- (id)getFirstWhileLocked;
- (void)lock;
- (void)unlock;
- (NSInteger)count;
- (void)removeObject:(id)object;

@end
