//
//  UMPrometheus.m
//  ulibprometheus
//
//  Created by Andreas Fink on 27.05.21.
//

#import "UMPrometheus.h"
#import "UMPrometheusMetric.h"

@implementation UMPrometheus

- (UMPrometheus *)init
{
    self = [super init];
    if(self)
    {
        _metrics = [[UMSynchronizedSortedDictionary alloc]init];
    }
    return self;
}

- (UMPrometheusMetric *)objectForKeyedSubscript:(id)key
{
    return (UMPrometheusMetric *)_metrics[key];
}

- (void)addObject:(UMPrometheusMetric *)o forKey:(id)key
{
    _metrics[key] = o;
}


- (NSString *)prometheusOutput
{
    NSMutableString *s = [[NSMutableString alloc]init];
    NSArray *keys = [_metrics allKeys];
    keys = [keys sortedArrayUsingSelector:@selector(compare:)];
    for(id key in keys)
    {
        UMPrometheusMetric *m = _metrics[key];
        [s appendString:m.prometheusOutput];
    }
    return s;
}
@end
