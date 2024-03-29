//
//  UMHTTPClient.m
//  ulib
//
//  Created by Andreas Fink on 23.11.16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
#include <unistd.h>
#import <ulib/UMHTTPClient.h>
#import <ulib/UMHTTPClientRequest.h>
#import <ulib/UMLayer.h>

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
    creq.url = [[NSURL alloc]initWithString:creq.urlString];
    if(creq.url==NULL)
    {
        NSLog(@"can not decode URL %@",creq.urlString);
    }

    [self addPendingSession:creq];
    creq.client = self;
//#ifdef LINUX
//    [self linuxWebFetch:creq];
//#else
    [creq performSelectorOnMainThread:@selector(start) withObject:NULL waitUntilDone:NO];
//#endif
}

- (NSString *)simpleSynchronousRequest:(UMHTTPClientRequest *)creq
{
    creq.delegate = self;
    creq.reference = creq;
    creq.responseStatusCode = 0;
    [self startRequest:creq];
    while(creq.reference!=NULL)
    {
        usleep(10000); /* sleep for 10ms */
    }
    if(creq.responseData)
    {
        return [[NSString alloc]initWithData:creq.responseData encoding:NSUTF8StringEncoding];
    }
    if(creq.responseStatusCode != 0)
    {
        return [NSString stringWithFormat:@"ERROR %03d",(int)creq.responseStatusCode];
    }
    return NULL;
}

- (void)linuxWebFetch:(UMHTTPClientRequest *)req
{
    req.url = [[NSURL alloc]initWithString:req.urlString];
    if(req.url==NULL)
    {
        NSLog(@"can not decode URL %@",req.urlString);
    }

    NSData *data = [NSData dataWithContentsOfURL:req.url];
    if(data.length > 0)
    {
        [self urlLoadCompletedForReference:req data:data status:200];
    }
    else
    {
        [self urlLoadCompletedForReference:req data:data status:404];
    }
}

- (void) urlLoadCompletedForReference:(id)ref data:(NSData *)data status:(NSInteger)statusCode
{
    UMHTTPClientRequest *creq = (UMHTTPClientRequest *)ref;
    creq.reference = NULL;
}

@end
