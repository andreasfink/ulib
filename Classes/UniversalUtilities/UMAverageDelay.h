//
//  UMAverageDelay.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"
#import "UMMutex.h"
@interface UMAverageDelay : UMObject
{
    int _size;
    NSMutableArray *_counters;
    UMMutex *_mutex;
}

- (UMAverageDelay *)init;
- (UMAverageDelay *)initWithSize:(int)size;
- (void) appendNumber:(NSNumber *)nr;
- (double) averageValue;

@end
