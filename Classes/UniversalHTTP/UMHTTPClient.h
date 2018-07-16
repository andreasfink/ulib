//
//  UMHTTPClient.h
//  ulib
//
//  Created by Andreas Fink on 23.11.16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"
#import "UMSynchronizedArray.h"
#import "UMTaskQueueMulti.h"

@class UMHTTPClientRequest;


@interface UMHTTPClient : UMObject
{
    UMSynchronizedArray *pendingOutgoingRequests;
    UMTaskQueueMulti *_taskQueue;
    BOOL _isSharedQueue;
}

- (void)addPendingSession:(UMHTTPClientRequest *)creq;
- (void)removePendingSession:(UMHTTPClientRequest *)creq;
- (void)startRequest:(UMHTTPClientRequest *)creq;

@end
