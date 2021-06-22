//
//  UMPrometheus.h
//  ulibprometheus
//
//  Created by Andreas Fink on 27.05.21.
//

#import "UMObject.h"
#import "UMSynchronizedSortedDictionary.h"

@class UMPrometheusMetric;

@interface UMPrometheus : UMObject
{
    UMSynchronizedSortedDictionary *_metrics;
}

- (id)objectForKeyedSubscript:(id)key;
- (void)addObject:(UMPrometheusMetric *)o forKey:(id)key;
- (void)removeObjectForKey:(id)key;
- (NSString *)prometheusOutput;
@end
