//
//  UniversalHTTP.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//
typedef enum
{
    HTTP_METHOD_GET = 0,
    HTTP_METHOD_POST = 1,
    HTTP_METHOD_HEAD = 2,
    HTTP_METHOD_OPTIONS = 3,
    HTTP_METHOD_TRACE = 4,
    HTTP_METHOD_PUT = 5,
    HTTP_METHOD_DELETE = 6
} UMHTTPMethod;

@class UMHTTPConnection;
@class UMHTTPServer;
@class UMHTTPRequest;
@class UMHTTPPageHandler;

#import "UMHTTPConnection.h"
#import "UMHTTPServer.h"
#import "UMHTTPPageHandler.h"
#import "NSString+UMHTTP.h"
#import "NSMutableString+UMHTTP.h"
#import "NSMutableArray+UMHTTP.h"
#import "NSDictionary+UMHTTP.h"
#import "NSData+UMHTTP.h"

#import "UMHTTPServerAuthorizeResult.h"
#import "NSMutableString+UMHTTP.h"
#import "NSMutableData+UMHTTP.h"

#import "UMHTTPRequest.h"

#import "UMHTTPPageHandler.h"
#import "UMHTTPCookie.h"
#import "UMHTTPPageRef.h"
#import "UMHTTPPageCache.h"
