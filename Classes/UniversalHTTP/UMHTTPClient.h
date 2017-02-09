//
//  UMHTTPClient.h
//  ulib
//
//  Created by Andreas Fink on 23.11.16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"
#import "UMSynchronizedArray.h"

@class UMHTTPClientRequest;

@interface UMHTTPClient : UMObject
{
    UMSynchronizedArray *pendingOutgoingRequests;
}

- (void)addPendingSession:(UMHTTPClientRequest *)creq;
- (void)removePendingSession:(UMHTTPClientRequest *)creq;
- (void)startRequest:(UMHTTPClientRequest *)creq;
- (NSString *)simpleSynchronousRequest:(UMHTTPClientRequest *)req;
- (void)simpleASynchronousRequest:(UMHTTPClientRequest *)req;

@end
