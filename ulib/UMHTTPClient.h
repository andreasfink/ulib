//
//  UMHTTPClient.h
//  ulib
//
//  Created by Andreas Fink on 23.11.16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMObject.h>
#import <ulib/UMSynchronizedArray.h>
#import <ulib/UMTaskQueueMulti.h>
#import <ulib/UMHTTPClientRequest.h>


@interface UMHTTPClient : UMObject<UMHTTPClientDelegateProtocol>
{
    UMSynchronizedArray *pendingOutgoingRequests;
    UMTaskQueueMulti *_taskQueue;
    BOOL _isSharedQueue;
}

- (void)addPendingSession:(UMHTTPClientRequest *)creq;
- (void)removePendingSession:(UMHTTPClientRequest *)creq;
- (void)startRequest:(UMHTTPClientRequest *)creq;
- (NSString *)simpleSynchronousRequest:(UMHTTPClientRequest *)creq;
@end
