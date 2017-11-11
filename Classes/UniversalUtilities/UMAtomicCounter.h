//
//  UMAtomicCounter.h
//  ulib
//
//  Created by Andreas Fink on 11.11.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UMMutex.h"

@interface UMAtomicCounter : NSObject
{
    int64_t _counter;
    UMMutex *_mutex;
}

- (UMAtomicCounter *)initWithInteger:(int64_t)value;
- (int64_t)counter;
- (void)setCounter:(int64_t)c;
- (void)increase:(int64_t)c;
- (void)decrease:(int64_t)c;
- (void)increase;
- (void)decrease;

- (UMAtomicCounter *)copyWithZone:(NSZone *)zone;
@end
