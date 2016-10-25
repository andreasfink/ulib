//
//  NSData+UMLog.m
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#include <Foundation/Foundation.h>

#ifdef LINUX

#import "NSData+UMLog.h"

@implementation NSData(UMLog)

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
@end

#endif
