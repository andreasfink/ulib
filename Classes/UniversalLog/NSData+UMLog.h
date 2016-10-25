//
//  NSData+UMLog.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#ifdef  LINUX
#import <Foundation/Foundation.h>
typedef NSUInteger NSDataSearchOptions;
#define  NSDataSearchBackwards (1UL << 0)
#define  NSDataSearchAnchored (1UL << 1)

@interface NSData(UMLog)

- (NSRange)rangeOfData:(NSData *)dataToFind options:(NSDataSearchOptions)mask range:(NSRange)searchRange;

@end
#endif
