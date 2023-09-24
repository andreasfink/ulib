//
//  UMHTTPPageCache.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMHTTPPageCache.h>
#import <ulib/UMHTTPPageRef.h>
#import <ulib/UMObject.h>

@implementation UMHTTPPageCache

- (id)initWithPrefix:(NSString *)pfx;
{
    self = [super init];
    if(self)
    {
        prefix = pfx;
        pages = [[NSMutableDictionary alloc]init];
    }
    return self;
}


-(UMHTTPPageRef *)getPage:(NSString *)path
{
    UMHTTPPageRef *ref = [pages objectForKey:path];
    if(ref)
    {
        return ref;
    }
    else
    {
        ref = [[UMHTTPPageRef alloc]initWithPath:path prefix:prefix];
    }
    return ref;
}

+ (BOOL)isValidPath:(NSString *)path
{
    /* this routine should check if the path is not using any .. or the like to go beyond the  root which is the prefix (but is not part of the passed path */
    return YES;
}
@end
