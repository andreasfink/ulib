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

- (void)addMetric:(UMPrometheusMetric *)o;
{
    _metrics[o.key] = o;
}

- (NSString *)prometheusOutput
{
    NSMutableString *s = [[NSMutableString alloc]init];
    NSArray *keys = [_metrics allKeys];
    keys = [keys sortedArrayUsingSelector:@selector(compare:)];
    NSString *oldhelp = @"";
    NSString *oldtype = @"";
    for(id key in keys)
    {
        UMPrometheusMetric *m = _metrics[key];
        NSString *help = m.prometheusOutputHelp;
        NSString *type = m.prometheusOutputType;
        NSString *data = m.prometheusOutputData;
        if(![help isEqualToString:oldhelp])
        {
            [s appendString:help];
        }
        if(![type isEqualToString:oldtype])
        {
            [s appendString:type];
        }
        [s appendString:data];
        oldhelp = help;
        oldtype = type;
    }
    return s;
}

- (void)removeObjectForKey:(id)key
{
    [_metrics removeObjectForKey:key];
}

@end
