//
//  UMHTTPPageHandler.m
//  SRAuth
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMHTTPPageHandler.h"
#import "UMHTTPRequest.h"

@implementation UMHTTPPageHandler

@synthesize path;

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
        callDelegate = cdel;
        callSelector = csel;
        authenticationDelegate = adel;
        authenticationSelector = asel;
        requiresAuthentication = auth;
        realm = r;
        path = p;
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
    if(requiresAuthentication==NO)
    {
        [req setAuthenticationStatus:UMHTTP_AUTHENTICATION_STATUS_NOT_REQUESTED];
    }
    if(!authenticationDelegate)
    {
        [req setAuthenticationStatus:UMHTTP_AUTHENTICATION_STATUS_FAILED];
    }
	if(![authenticationDelegate respondsToSelector:authenticationSelector] )
    {
        [req setAuthenticationStatus:UMHTTP_AUTHENTICATION_STATUS_FAILED];
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [authenticationDelegate performSelector:authenticationSelector withObject:req];
#pragma clang diagnostic pop
}

- (void) call:(UMHTTPRequest *)req;
{
    if(!callDelegate)
    {
        [req setNotFound];
        return;
    }
	if(! [callDelegate respondsToSelector:callSelector] )
    {
        [req setNotFound];
        return;
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [callDelegate performSelector:callSelector withObject:req];
#pragma clang diagnostic pop
}
@end
