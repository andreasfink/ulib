//
//  UMHTTPCookie.h
//  ulib
//
//  Created by Andreas Fink on 07.11.13.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ulib/UMObject.h>
@interface UMHTTPCookie : UMObject
{
    NSString *_name;
    NSString *_value;
    NSDate *_expiration;
    NSString *_version;
    NSString *_path;
    NSString *_domain;
    NSString *_maxage;
    NSString *_secure;
    NSString *_comment;

    NSString *raw;
}

@property(readwrite,strong)   NSString *name;
@property(readwrite,strong)   NSString *value;
@property(readwrite,strong)   NSDate *expiration;
@property(readwrite,strong)   NSString *version;
@property(readwrite,strong)   NSString *path;
@property(readwrite,strong)   NSString *domain;
@property(readwrite,strong)   NSString *maxage;
@property(readwrite,strong)   NSString *secure;
@property(readwrite,strong)   NSString *comment;

@property(readwrite,strong)   NSString *raw;

@end


