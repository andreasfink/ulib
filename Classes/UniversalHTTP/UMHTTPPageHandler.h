//
//  UMHTTPPageHandler.h
//  SRAuth
//
//  Created by Andreas Fink on 13.09.11.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"
@class UMHTTPRequest;

@interface UMHTTPPageHandler : UMObject
{
    NSString    *path;
    id          callDelegate;
    SEL         callSelector;
    BOOL        requiresAuthentication;
    id          authenticationDelegate;
    SEL         authenticationSelector;
    NSString    *realm;
}

@property(readonly,strong) NSString *path;

- (UMHTTPPageHandler *)initWithPath:(NSString *)p 
                       callDelegate:(id)cdel
                       callSelector:(SEL)csel
               authenticateDelegate:(id)adel
               authenticateSelector:(SEL)asel
                   mustAuthenticate:(BOOL)auth
                              realm:(NSString *)r;


- (UMHTTPPageHandler *)initWithPath:(NSString *)p 
                       callDelegate:(id)cdel
                       callSelector:(SEL)csel;

- (void)call:(UMHTTPRequest *)req;

+ (UMHTTPPageHandler *)pageHandlerWithPath:(NSString *)p
                              callDelegate:(id)cdel
                              callSelector:(SEL)csel
                      authenticateDelegate:(id)adel
                      authenticateSelector:(SEL)asel
                          mustAuthenticate:(BOOL)auth
                                     realm:(NSString *)r;

+ (UMHTTPPageHandler *)pageHandlerWithPath:(NSString *)p
                              callDelegate:(id)cdel
                              callSelector:(SEL)csel;
@end
