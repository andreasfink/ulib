//
//  UMHTTPClientRequest.m
//  ulib
//
//  Created by Andreas Fink on 23.11.16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMHTTPClientRequest.h"
#import "UMHTTPClient.h"

@implementation UMHTTPClientRequest

@synthesize theRequest;
@synthesize urlString;
@synthesize url;
@synthesize client;
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
            policy = NSURLRequestReloadIgnoringCacheData;
        }
        theRequest = [NSMutableURLRequest requestWithURL:url
                                             cachePolicy:policy
                                         timeoutInterval:timeout];
    }
    return self;
}

- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
    _responseStatusCode = res.statusCode;
}

- (void)connection:(NSURLConnection *)connection
    didReceiveData:(NSData *)response
{
    if(_responseData == NULL)
    {
        _responseData = [response mutableCopy];
    }
    else
    {
        [_responseData appendData:response];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [_delegate urlLoadCompletedForReference:_reference data:_responseData status:_responseStatusCode];
}

@end
