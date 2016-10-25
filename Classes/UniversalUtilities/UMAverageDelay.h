//
//  UMAverageDelay.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
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
