//
//  UMTestDelegate.h
//  ulib
//
//  Created by Aarno Syvänen on 08.05.12.
//  //  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UMObject.h"
#import "UMHTTPServerAuthoriseResult.h"
#import "UMHTTPServer.h"

@class UMSocket, UMHTTPRequest;

@interface UMAuthoriseConnectionDelegate : UMObject <UMHTTPServerAuthoriseConnectionDelegate>
{
    NSString *serverAllowIP;
    NSString *serverDenyIP;
    NSString *subsection;
}

@property(readwrite,strong)	NSString *serverAllowIP;
@property(readwrite,strong)	NSString *serverDenyIP;
@property(readwrite,strong)	NSString *subsection;

- (UMAuthoriseConnectionDelegate *)initWithConfigFile:(NSString *)file;
- (UMHTTPServerAuthoriseResult) httpAuthoriseConnection:(UMSocket *)us;
- (void) httpAuthoriseUrl:(UMHTTPRequest *)req;

@end

@interface UMDelegate : UMObject 
{
    NSData *content;
    NSString *subsection;
}

@property(readwrite,strong)	NSData *content;
@property(readwrite,strong)	NSString *subsection;

- (UMDelegate *)initWithConfigFile:(NSString *)file;

@end

@interface UMHTTPDelegate : UMDelegate <UMHTTPServerHttpGetDelegate>

- (void) httpGet:(UMHTTPRequest *)req;

@end


@interface UMHTTPPostDelegate : UMDelegate <UMHTTPServerHttpPostDelegate>

- (void) httpPost:(UMHTTPRequest *)req;

@end

@interface UMHTTPHeadDelegate : UMDelegate <UMHTTPServerHttpHeadDelegate>

- (void) httpHead:(UMHTTPRequest *)req;

@end

@interface UMHTTPOptionsDelegate : UMDelegate <UMHTTPServerHttpOptionsDelegate>

- (void) httpOptions:(UMHTTPRequest *)req;

@end

@interface UMHTTPTraceDelegate : UMDelegate <UMHTTPServerHttpTraceDelegate>

- (NSString *)rebuildRequestWithMethod:(NSString *)m withURL:(NSString *)u withHeaders:(NSMutableArray *)headers withBody:(NSString *)body;
- (void) httpTrace:(UMHTTPRequest *)req;

@end

@interface UMHTTPPutDelegate : UMDelegate <UMHTTPServerHttpPutDelegate>

- (void) httpPut:(UMHTTPRequest *)req;

@end

@interface UMHTTPDeleteDelegate : UMDelegate <UMHTTPServerHttpDeleteDelegate>

- (void) httpDelete:(UMHTTPRequest *)req;

@end
