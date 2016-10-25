//
//  UMHTTPPageCache.h
//  ulib
//
//  Created by Andreas Fink on 11.02.14.
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#import "UMObject.h"

@class UMHTTPPageRef;

@interface UMHTTPPageCache : UMObject
{
    NSMutableDictionary *pages;
    NSString *prefix;
}

- (UMHTTPPageCache *)initWithPrefix:(NSString *)pfx;
- (UMHTTPPageRef *)getPage:(NSString *)path;
+ (BOOL)isValidPath:(NSString *)path;

@end
