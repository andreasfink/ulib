//
//  UMHTTPPageRef.h
//  ulib
//
//  Created by Andreas Fink on 11.02.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"

@interface UMHTTPPageRef : UMObject
{
    NSString *path;
    NSData  *data;
    NSString *mimeType;
/* private stuff: */
    void     *_dataPtr;
    size_t  _dataSize;
    int     _fd;

}

@property (readwrite,strong) NSString *path;
@property (readwrite,strong) NSData  *data;
@property (readwrite,strong) NSString *mimeType;

-(UMHTTPPageRef *)initWithPath:(NSString *)path prefix:(NSString *)prefix;
-(UMHTTPPageRef *)initWithPath:(NSString *)path;
+(NSString *)defaultPrefix;

@end
