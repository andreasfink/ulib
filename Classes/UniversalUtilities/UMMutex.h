//
//  UMMutex.h
//  ulib
//
//  Created by Andreas Fink on 11.11.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>
#import <pthread.h>

@interface UMMutex : NSObject
{
    pthread_mutex_t *_mutexLock;
}

- (void)lock;
- (void)unlock;
- (int)tryLock;

@end
