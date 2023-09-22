//
//  UMUUID.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMObject.h>

@interface UMUUID : UMObject
+ (NSString *)UUID;
+ (NSString *)UUID16String;
+ (NSData *)UUID16;

@end
