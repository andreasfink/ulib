//
//  UMAtomicDate.h
//  ulib
//
//  Created by Andreas Fink on 11.11.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UMMutex.h"

@interface UMAtomicDate : NSObject
{
    NSDate *_date;
    UMMutex *_mutex;
}

- (UMAtomicDate *)initWithDate:(NSDate *)d;
- (NSDate *)date;
- (void)setDate:(NSDate *)d;
- (NSTimeInterval)timeIntervalSinceDate:(NSDate *)since;
- (NSTimeInterval)timeIntervalSinceNow;
- (NSTimeInterval)age;
- (void)touch;
- (UMAtomicDate *)copyWithZone:(NSZone *)zone;
-(id)proxyForJson;

@end
