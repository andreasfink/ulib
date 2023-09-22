//
//  NSData+UMSocket.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/NSData+UMSocket.h>

@implementation NSData (UMSocket)

- (NSRange) rangeOfData_dd:(NSData *)dataToFind
{
    return [self rangeOfData_dd:dataToFind startingFrom:0];
}

- (NSRange) rangeOfData_dd:(NSData *)dataToFind startingFrom:(long)start
{
    const void * bytes = [self bytes];
    NSInteger length = [self length];
    NSRange foundRange = {NSNotFound, 0};


    length = length - dataToFind.length +1;
    if(length<1)
    {
        return foundRange;
    }

    for (NSInteger index = start; index < length;index++)
    {
        if(memcmp (&bytes[index], dataToFind.bytes,dataToFind.length)==0)
        {
            foundRange.location =index;
            foundRange.length = dataToFind.length;
            return foundRange;
        }
    }
    return foundRange;
}


@end
