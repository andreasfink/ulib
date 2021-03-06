//
//  NSData+UMLog.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#if defined(LINUX) || defined(FREEBSD)
/* this stuff is not in Gnustep but in OSX so we emulate it here */
#import <Foundation/Foundation.h>
typedef NSUInteger NSDataSearchOptions;
#define  NSDataSearchBackwards (1UL << 0)
#define  NSDataSearchAnchored (1UL << 1)

@interface NSData(UMLog)

- (NSRange)rangeOfData:(NSData *)dataToFind options:(NSDataSearchOptions)mask range:(NSRange)searchRange;

@end


#endif
