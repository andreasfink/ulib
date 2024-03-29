//
//  UMHTTPClientRequest.h
//  ulib
//
//  Created by Andreas Fink on 23.11.16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMObject.h>
#import <ulib/UMTaskQueueTask.h>

@class UMHTTPClient;


@protocol UMHTTPClientDelegateProtocol
- (void) urlLoadCompletedForReference:(id)ref data:(NSData *)data status:(NSInteger)statusCode;
@end
    
@interface UMHTTPClientRequest : UMTaskQueueTask
{
    NSURLRequest                        *_theRequest;
    NSString                            *_urlString;
    NSURL                               *_url;
    UMHTTPClient                        *_client;
    id<UMHTTPClientDelegateProtocol>    _delegate;
    id                                  _reference;
    NSURLConnection                     *_urlCon;
    NSInteger                           _responseStatusCode;
    NSMutableData                       *_responseData;
}
@property(readwrite,strong) NSURLRequest *theRequest;
@property(readwrite,strong) NSString *urlString;
@property(readwrite,strong) NSURL *url;
@property(readwrite,strong) UMHTTPClient *client;
@property(readwrite,strong) id<UMHTTPClientDelegateProtocol> delegate;
@property(readwrite,strong) id reference;
@property(readwrite,strong) NSURLConnection *urlCon;
@property(readwrite,assign) NSInteger responseStatusCode;
@property(readonly,copy) NSData *responseData;


- (UMHTTPClientRequest *)initWithURLString:(NSString *)urls
                                withChache:(BOOL)cache
                                   timeout:(NSTimeInterval) timeout;

- (void)start;

@end
