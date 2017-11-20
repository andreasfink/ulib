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

#ifdef LINUX
    creq.urlCon = [[NSURLConnection alloc]initWithRequest:creq.theRequest
                                  delegate:creq];
#else
/* note: this triggers a depreciated waring under recent MacOS X versions.
 However we have to stick to this as Gnustep doesnt know NSURLSession yet */
    
    creq.urlCon = [[NSURLConnection alloc]initWithRequest:creq.theRequest
                                  delegate:creq
                          startImmediately:YES];
#endif
}

- (NSString *)simpleSynchronousRequest:(UMHTTPClientRequest *)req
{
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
