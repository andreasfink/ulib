//
//  UMPrometheus.h
//  ulibprometheus
//
//  Created by Andreas Fink on 27.05.21.
//

#import <ulib/UMObject.h>
#import <ulib/UMSynchronizedSortedDictionary.h>

@class UMPrometheusMetric;

@interface UMPrometheus : UMObject
{
    UMSynchronizedSortedDictionary *_metrics;
}

- (id)objectForKeyedSubscript:(id)key;
- (void)addObject:(UMPrometheusMetric *)o forKey:(id)key;
- (void)addMetric:(UMPrometheusMetric *)o;
- (void)removeObjectForKey:(id)key;
- (NSString *)prometheusOutput;
@end
