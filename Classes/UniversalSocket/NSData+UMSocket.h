//
//  NSData+UMSocket.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface  NSData (UMSocket)
- (NSRange) rangeOfData_dd:(NSData *)dataToFind;
- (NSRange) rangeOfData_dd:(NSData *)dataToFind startingFrom:(long)i;
@end
