//
//  UMHTTPURLHandler.h
//  UniversalHTTP
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//


#import "UMObject.h"

#import "UMHTTPServerAuthorizeResult.h"

@class UMHTTPRequest;
@class UMSocket;


@protocol UMHTTPURLHandlerMethod <NSObject>
- (UMHTTPServerAuthorizeResult)  httpAuthorizeRequest:(UMSocket *)sock;
@end

@interface UMHTTPURLHandler : NSObject
{
	BOOL						requiresAuthentication;

	id<UMHTTPURLHandlerMethod>	__unsafe_unretained authenticationDelegate;
	SEL							authenticateMethodToCall;

	id<UMHTTPURLHandlerMethod>	__unsafe_unretained requestDelegate;
	SEL							requestMethodToCall;

	NSURL						*uri;
}

@property (readwrite,assign)		BOOL	requiresAuthentication;

@property (readwrite,strong)		NSURL	*uri;
@property (readwrite,unsafe_unretained)		id<UMHTTPURLHandlerMethod>	requestDelegate;
@property (readwrite,assign)		SEL		requestMethodToCall;
@property (readwrite,unsafe_unretained)		id<UMHTTPURLHandlerMethod>	authenticationDelegate;
@property (readwrite,assign)		SEL		authenticateMethodToCall;

-(int) isEqualUri:(NSURL *)u;
-(void)authenticateIt:(UMHTTPRequest *)req;
-(void)callIt:(UMHTTPRequest *)req;

@end
