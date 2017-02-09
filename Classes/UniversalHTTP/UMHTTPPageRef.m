//
//  UMHTTPPageRef.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#include <sys/mman.h>
#ifndef MAP_FILE
#define	MAP_FILE 0
#endif

#include <fcntl.h>
#include <sys/stat.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>


#import "UMHTTPPageRef.h"
#import "NSString+UniversalObject.h"

@implementation UMHTTPPageRef

@synthesize path;
@synthesize data;
@synthesize mimeType;

+ (NSString *)defaultPrefix
{
    return @"/usr/local/var/smsrouter/web";
} 

-(UMHTTPPageRef *)initWithPath:(NSString *)thePath prefix:(NSString *)prefix;
{
    self = [super init];
    if(self)
    {
        if(prefix==nil)
        {
            prefix = [UMHTTPPageRef defaultPrefix];
        }
        self.path = thePath;
        int i = chdir(prefix.UTF8String);
        int eno = errno;
        if(i !=0)
        {
            NSLog(@"error %d while chdir(0%@')",eno,path);
            return NULL;
        }

        if(thePath.length == 0)
        {
            return NULL;
        }
        if([thePath characterAtIndex:0]=='/')
        {
            thePath = [thePath substringFromIndex:1];
        }
        if(thePath.length>1)
        {
            if([thePath characterAtIndex:(thePath.length-1)]=='/')
            {
                thePath = [NSString stringWithFormat:@"%@index.html",thePath];
            }
        }
        thePath = [thePath fileNameRelativeToPath:prefix];
        self.data = [NSData dataWithContentsOfFile:thePath];
        self.mimeType = [self mimeTypeForExtension:thePath];
    }
    return self;
}

-(UMHTTPPageRef *)initWithPath:(NSString *)thePath
{
    return [self initWithPath:thePath prefix:nil];
}

- (NSString*)mimeTypeForExtension:(NSString*)ext
{
    if(!ext)
    {
        return nil;
    }
    if([ext hasSuffix:@"txt"])
    {
        return @"text/plain; charset=\"UTF-8\"";
    }
    else if([ext hasSuffix:@"html"])
    {
        return @"text/html; charset=\"UTF-8\"";
    }
    else if([ext hasSuffix:@"css"])
    {
        return @"text/css";
    }
    else if([ext hasSuffix:@"png"])
    {
        return @"image/png";
    }
    else if([ext hasSuffix:@"jpg"])
    {
        return @"image/jpeg";
    }
    else if([ext hasSuffix:@"jpeg"])
    {
        return @"image/jpeg";
    }
    else if([ext hasSuffix:@".gif"])
    {
        return @"image/gif";
    }

#if 0
    NSString* theMimeType = nil;
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                            (CFStringRef)ext, NULL);
    if(!UTI)
    {
        return nil;
    }
    CFStringRef registeredType = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType);
    if(!registeredType ) // check for edge case
    {
    	if([ext isEqualToString:@"html"])
        {
    		theMimeType = @"video/x-m4v";
        }
        else if( [ext isEqualToString:@"m4p"] )
        {
    		theMimeType = @"audio/x-m4p";
        }
        // handle anything else here that you know is not registered
    } else {
    	theMimeType = NSMakeCollectable(registeredType);
    }
    
    CFRelease(UTI);
    return theMimeType;

#endif
    
    return nil;
}

@end


