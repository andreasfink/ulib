//
//  UMHTTPURLHandler.m
//  UniversalHTTP
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#import "UMHTTPURLHandler.h"
#import "UMHTTPRequest.h"

@implementation UMHTTPURLHandler

@synthesize uri;
@synthesize requestDelegate;
@synthesize authenticationDelegate;
@synthesize requestMethodToCall;
@synthesize authenticateMethodToCall;
@synthesize requiresAuthentication;

-(int) isEqualUri:(NSURL *)u
{
	return [u isEqual:uri];
}

-(void)callIt:(UMHTTPRequest *)req
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	[requestDelegate performSelector:requestMethodToCall withObject:req];
#pragma clang diagnostic pop
}

-(void)authenticateIt:(UMHTTPRequest *)req
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	[authenticationDelegate performSelector:authenticateMethodToCall withObject:req];
#pragma clang diagnostic pop
}


#if 0
-(NSString *)description
{
	return [NSString stringWithFormat:
	@"uri:%@\n"
	"request [%@]\n"
	"methodToCall:%@"
	method = NSStringFromSelector(setWidthHeight);

}
#endif
	
@end
