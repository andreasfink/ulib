//
//  UMPool.h
//  ulib
//
//  Created by Andreas Fink on 24.11.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"
#import "UMMutex.h"

#define UMPOOL_QUEUES_COUNT 32

@interface UMPool : UMObject
{
    NSMutableArray  *_queues[UMPOOL_QUEUES_COUNT];
    UMMutex         *_poolLock[UMPOOL_QUEUES_COUNT];
    int _rotary;
}

- (UMPool *)init;
- (void)append:(id)obj;
- (void)removeObject:(id)obj;
//- (void)removeObjectIdenticalTo:(id)obj;
- (id)getAny;
- (NSInteger)count;

@end
