//
//  NSString+UMSocket.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import <Foundation/Foundation.h>

@interface  NSString (UMSocket)

- (BOOL)isIPv4;
- (BOOL)isIPv6;
- (NSData *)binaryIPAddress;
- (NSData *)binaryIPAddress4;
- (NSData *)binaryIPAddress6;

@end
