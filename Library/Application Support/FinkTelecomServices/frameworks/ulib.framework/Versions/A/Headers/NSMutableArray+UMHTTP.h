//
//  NSMutableArray+UMHTTTP.h
//  ulib
//
//  Created by Andreas Fink on 23.10.12.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>

@class UMSocket;
@interface NSMutableArray (HTTPHeader)

+ (BOOL)nameOf:(NSString *)header is:(NSString *)name;
- (long)removeAllWithName:(NSString *)name;
- (void)getHeaderAtIndex:(long)i withName:(NSString **)name andValue:(NSMutableString **)value;
- (NSString *)findFirstWithName:(NSString *)name;
- (int)readSomeHeadersFrom:(UMSocket *)sock;
- (void)addHeaderWithName:(NSString *)name andValue:(NSString *)value;
- (void)addBasicAuthWithUserName:(NSString *)username andPassword:(NSString *)password;
- (void)proxyAddAuthenticationWithUserName:(NSString *)username andPassword:(NSString *)password;
- (void)getContentType:(NSMutableString **)type andCharset:(NSMutableString **)charset;

@end
