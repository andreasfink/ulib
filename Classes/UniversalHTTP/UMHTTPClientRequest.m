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

- (UMHTTPClientRequest *)initWithURLString:(NSString *)urls
                                withChache:(BOOL)cache
                                   timeout:(NSTimeInterval) timeout
{
    self = [super init];
    if(self)
    {
        _urlString = urls;
        _url = [NSURL URLWithString:urls];

        NSURLRequestCachePolicy policy;
        if(cache)
        {
            policy = NSURLRequestUseProtocolCachePolicy;
        }
        else
        {
            policy = NSURLRequestReloadIgnoringCacheData;
        }
        _theRequest = [NSMutableURLRequest requestWithURL:_url
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

- (void)start
{

#if defined(LINUX) || defined(FREEBSD)
    _urlCon = [[NSURLConnection alloc]initWithRequest:_theRequest
                                            delegate:self];
#else
    /* note: this triggers a depreciated waring under recent MacOS X versions.
     However we have to stick to this as Gnustep doesnt know NSURLSession yet */
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    _urlCon = [[NSURLConnection alloc]initWithRequest:_theRequest
                                            delegate:self
                                    startImmediately:YES];
#pragma clang diagnostic pop

#endif
}


- (void)main
{
    @autoreleasepool
    {
        if(_url==NULL)
        {
            return;
        }
        NSError *err = NULL;
        [NSString stringWithContentsOfURL:_url encoding:NSUTF8StringEncoding error:&err];
        if(err)
        {
            NSLog(@"Error %@ while loading url %@",err,_urlString);
        }
    }
}
@end
