//
//  UMHTTPWebSocketDelegateProtocol.h
//  ulib
//
//  Created by Andreas Fink on 08.02.2020.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ulib/UMHTTPAuthenticationStatus.h>

@class UMHTTPRequest;
@class UMHTTPConnection;
@class UMHTTPWebSocketFrame;

@protocol UMHTTPWebSocketDelegateProtocol <NSObject>
- (id<UMHTTPWebSocketDelegateProtocol>) openWebSocketProtocol:(NSString *)protocol
                                                      version:(NSString *)version
                                                       origin:(NSString *)orgin
                                                      request:(UMHTTPRequest *)req;
- (void)handleWebSocketFrame:(UMHTTPWebSocketFrame *)frame
                onConnection:(UMHTTPConnection *)con;
@end

