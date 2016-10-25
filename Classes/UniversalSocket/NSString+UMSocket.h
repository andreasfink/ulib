//
//  NSString+UMSocket.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//
//

#import <Foundation/Foundation.h>

@interface  NSString (UMSocket)

- (BOOL)isIPv4;
- (BOOL)isIPv6;

@end
