//
//  UMHTTPURLHandler.h
//  UniversalHTTP
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//


#import <ulib/UMObject.h>

#import <ulib/UMHTTPServerAuthoriseResult.h>

@class UMHTTPRequest;
@class UMSocket;


@protocol UMHTTPURLHandlerMethod <NSObject>
- (UMHTTPServerAuthoriseResult)  httpAuthoriseRequest:(UMSocket *)sock;
@end

@interface UMHTTPURLHandler : NSObject
{
	BOOL						_requiresAuthentication;
	id<UMHTTPURLHandlerMethod>	__unsafe_unretained _authenticationDelegate;
	SEL							_authenticateMethodToCall;
	id<UMHTTPURLHandlerMethod>	__unsafe_unretained _requestDelegate;
	SEL							_requestMethodToCall;
	NSURL						*_uri;
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
