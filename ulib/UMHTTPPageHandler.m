//
//  UMHTTPPageHandler.m
//  SRAuth
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMHTTPPageHandler.h>
#import <ulib/UMHTTPRequest.h>

@implementation UMHTTPPageHandler

- (UMHTTPPageHandler *)initWithPath:(NSString *)p 
                       callDelegate:(id)cdel
                       callSelector:(SEL)csel
{
    return [self initWithPath:p
                 callDelegate:cdel 
                 callSelector:csel
         authenticateDelegate:NULL 
         authenticateSelector:NULL
             mustAuthenticate:NO
                        realm:NULL];
}


- (UMHTTPPageHandler *)initWithPath:(NSString *)p 
                       callDelegate:(id)cdel
                       callSelector:(SEL)csel
               authenticateDelegate:(id)adel
               authenticateSelector:(SEL)asel
                   mustAuthenticate:(BOOL)auth
                              realm:(NSString *)r
{
    self = [super init];
    if(self)
	{
        _callDelegate = cdel;
        _callSelector = csel;
        _authenticationDelegate = adel;
        _authenticationSelector = asel;
        _requiresAuthentication = auth;
        _realm = r;
        _path = p;
    }
    return self;
}



+ (UMHTTPPageHandler *)pageHandlerWithPath:(NSString *)p
                       callDelegate:(id)cdel
                       callSelector:(SEL)csel
               authenticateDelegate:(id)adel
               authenticateSelector:(SEL)asel
                   mustAuthenticate:(BOOL)auth
                              realm:(NSString *)r
{
    UMHTTPPageHandler *pageHandler = [[UMHTTPPageHandler alloc]initWithPath:p
                                                               callDelegate:cdel
                                                               callSelector:csel
                                                       authenticateDelegate:adel
                                                       authenticateSelector:asel
                                                           mustAuthenticate:auth
                                                                      realm:r];
    return pageHandler;
}

+ (UMHTTPPageHandler *)pageHandlerWithPath:(NSString *)p
                              callDelegate:(id)cdel
                              callSelector:(SEL)csel
{
    UMHTTPPageHandler *pageHandler = [[UMHTTPPageHandler alloc]initWithPath:p
                                                               callDelegate:cdel
                                                               callSelector:csel];
    return pageHandler;
}

- (void) authenticate:(UMHTTPRequest *)req
{
    if(_requiresAuthentication==NO)
    {
        req.authenticationStatus = UMHTTP_AUTHENTICATION_STATUS_NOT_REQUESTED;
    }
    if(!_authenticationDelegate)
    {
        req.authenticationStatus=UMHTTP_AUTHENTICATION_STATUS_FAILED;
    }
	if(![_authenticationDelegate respondsToSelector:_authenticationSelector] )
    {
        req.authenticationStatus=UMHTTP_AUTHENTICATION_STATUS_FAILED;
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [_authenticationDelegate performSelector:_authenticationSelector withObject:req];
#pragma clang diagnostic pop
}

- (void) call:(UMHTTPRequest *)req;
{
    if(!_callDelegate)
    {
        [req setNotFound];
        return;
    }
	if(! [_callDelegate respondsToSelector:_callSelector] )
    {
        [req setNotFound];
        return;
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [_callDelegate performSelector:_callSelector withObject:req];
#pragma clang diagnostic pop
}
@end
