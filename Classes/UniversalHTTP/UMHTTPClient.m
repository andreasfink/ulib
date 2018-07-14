//
//  UMHTTPClient.m
//  ulib
//
//  Created by Andreas Fink on 23.11.16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMHTTPClient.h"
#import "UMHTTPClientRequest.h"
#import "UMLayer.h"

@implementation UMHTTPClient


- (void)addPendingSession:(UMHTTPClientRequest *)creq
{
    [pendingOutgoingRequests addObject:creq];
}

- (void)removePendingSession:(UMHTTPClientRequest *)creq
{
    [pendingOutgoingRequests removeObject:creq];
}

- (void)startRequest:(UMHTTPClientRequest *)creq
{
    [self addPendingSession:creq];
    creq.client = self;
    [creq performSelectorOnMainThread:@selector(start) withObject:NULL waitUntilDone:NO];
}

@end
