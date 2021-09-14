//
//  NSData+UMLog.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#include <Foundation/Foundation.h>

#if defined(LINUX) || defined(FREEBSD)
/* this stuff is not in Gnustep but in OSX so we emulate it here */

#import "NSData+UMLog.h"

@implementation NSData(UMLog)

#ifdef OLD_GNUSTEP

- (NSRange)rangeOfData:(NSData *)dataToFind options:(NSDataSearchOptions)mask range:(NSRange)searchRange
{
    const void * bytes = [self bytes];
    NSUInteger length = [self length];
    
    const void * searchBytes = [dataToFind bytes];
    NSUInteger searchLength = [dataToFind length];
    NSUInteger searchIndex = 0;
    
    NSRange foundRange = {NSNotFound, searchLength};
    NSUInteger index;
    for (index = searchIndex; index < length; ++index)
    {
        if (((char *)bytes)[index] == ((char *)searchBytes)[searchIndex])
        {
            //the current character matches
            if (foundRange.location == NSNotFound)
            {
                foundRange.location = index;
            }
            ++searchIndex;
            if (searchIndex >= searchLength)
            {
                return foundRange;
            }
        }
        else
        {
            searchIndex = 0;
            foundRange.location = NSNotFound;
        }
    }
    return foundRange;
}
#endif
@end

#endif
