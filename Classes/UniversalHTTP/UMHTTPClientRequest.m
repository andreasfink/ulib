//
//  UMHTTPClientRequest.m
//  ulib
//
//  Created by Andreas Fink on 23.11.16.
//  Copyright © 2016 Andreas Fink. All rights reserved.
//

#import "UMHTTPClientRequest.h"
#import "UMHTTPClient.h"

@implementation UMHTTPClientRequest

@synthesize theRequest;
@synthesize urlString;
@synthesize url;
@synthesize client;
@synthesize delegate;
@synthesize urlCon;

- (UMHTTPClientRequest *)initWithURLString:(NSString *)urls
                                withChache:(BOOL)cache
                                   timeout:(NSTimeInterval) timeout
{
    self = [super init];
    if(self)
    {
        urlString = urls;
        url = [NSURL URLWithString:urls];

        NSURLRequestCachePolicy policy;
        if(cache)
        {
            policy = NSURLRequestUseProtocolCachePolicy;
        }
        else
        {
            policy = NSURLRequestReloadIgnoringLocalCacheData;
        }
        theRequest = [NSMutableURLRequest requestWithURL:url
                                             cachePolicy:policy
                                         timeoutInterval:timeout];
    }
}
@end
