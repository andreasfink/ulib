//
//  UMHTTPURLHandler.m
//  UniversalHTTP
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMHTTPURLHandler.h>
#import <ulib/UMHTTPRequest.h>

@implementation UMHTTPURLHandler


-(int) isEqualUri:(NSURL *)u
{
	return [u isEqual:_uri];
}

-(void)callIt:(UMHTTPRequest *)req
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	[_requestDelegate performSelector:_requestMethodToCall withObject:req];
#pragma clang diagnostic pop
}

-(void)authenticateIt:(UMHTTPRequest *)req
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	[_authenticationDelegate performSelector:_authenticateMethodToCall withObject:req];
#pragma clang diagnostic pop
}
	
@end
