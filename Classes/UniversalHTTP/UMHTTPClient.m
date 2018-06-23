//
//  UMHTTPClient.m
//  ulib
//
//  Created by Andreas Fink on 23.11.16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMHTTPClient.h"
#import "UMHTTPClientRequest.h"

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

- (NSString *)simpleSynchronousRequest:(UMHTTPClientRequest *)req
{
    NSURL *url = req.url;
    if(url==NULL)
    {
        return @"";
    }
    NSError *err = NULL;
    NSString *html = [NSString stringWithContentsOfURL:req.url
                                              encoding:NSUTF8StringEncoding
                                                 error:&err];
    if(err)
    {
        NSLog(@"Error %@ while loading URL %@",err,req.urlString);
    }
    return html;
}

- (void)simpleASynchronousRequest:(UMHTTPClientRequest *)req
{

    [self runSelectorInBackground:@selector(simpleSynchronousRequest:)
                       withObject:req
                             file:__FILE__
                             line:__LINE__
                         function:__func__];
}

@end
