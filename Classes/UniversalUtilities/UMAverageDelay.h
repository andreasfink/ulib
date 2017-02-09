//
//  UMAverageDelay.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"

@interface UMAverageDelay : UMObject
{
    int size;
    NSMutableArray *counters;
}

- (UMAverageDelay *)init;
- (UMAverageDelay *)initWithSize:(int)size;
- (void) appendNumber:(NSNumber *)nr;
- (double) averageValue;

@end
