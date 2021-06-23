//
//  UMPrometheusMetric.m
//  ulibprometheus
//
//  Created by Andreas Fink on 27.05.21.
//

#import "UMPrometheusMetric.h"

@implementation UMPrometheusMetric

- (UMPrometheusMetric *)init
{
    self = [super init];
    if(self)
    {
        _lock = [[UMMutex alloc]initWithName:@"UMPrometheusMetricLock"];
        _value = @(0);
    }
    return self;
}

- (UMPrometheusMetric *)initWithMetricName:(NSString *)name subname1:(NSString *)sub1 subvalue1:(NSString *)val1 type:(UMPrometheusMetricType)t
{
    self = [super init];
    if(self)
    {
        _lock = [[UMMutex alloc]initWithName:@"UMPrometheusMetricLock"];
        _value = @(0);
        _metricName = name;
        _subname1 = sub1;
        _subvalue1 =val1;
        _metricType = t;
    }
    return self;
}


- (void)update
{
    [_lock lock];
    if(_delegate)
    {
        [_delegate updatePrometheusData:self];
    }
    else
    {
        [self updatePrometheusData:self];
    }
    [_lock unlock];
}


- (void)updatePrometheusData:(UMPrometheusMetric *)metric
{
    
}


- (NSString *)key
{
    NSMutableString *s = [[NSMutableString alloc]initWithString:_metricName];
    if((_subname1.length > 0) && (_subvalue1.length > 0))
    {
        [s appendString:@"{"];
        [s appendString:_subname1];
        [s appendString:@"=\""];
        [s appendString:_subvalue1];
        [s appendString:@"\""];

        if((_subname2.length > 0) && (_subvalue2.length > 0))
        {
            [s appendString:@","];
            [s appendString:_subname2];
            [s appendString:@"=\""];
            [s appendString:_subvalue2];
            [s appendString:@"\""];
            if((_subname3.length > 0) && (_subvalue3.length > 0))
            {
                [s appendString:@","];
                [s appendString:_subname3];
                [s appendString:@"=\""];
                [s appendString:_subvalue3];
                [s appendString:@"\""];
            }
        }
        [s appendString:@"}"];
    }
    return s;
}

- (NSString *)prometheusOutput
{
    NSMutableString *s = [[NSMutableString alloc]init];
    NSString *key = [self key];
    [_lock lock];
    if(_subname1.length == 0)
    {
        /* if we have a subname object, we expect a main object to provide help and type */
        if(_help.length > 0)
        {
            [s appendString:@"# HELP "];
            [s appendString:key];
            [s appendString:@" "];
            [s appendString:_help];
            [s appendString:@"\n"];
        }
        [s appendString:@"# TYPE "];
        [s appendString:key];
        switch(_metricType)
        {

            case UMPrometheusMetricType_gauge:
                [s appendString:@" gauge\n"];
                break;
            case UMPrometheusMetricType_histogram:
                [s appendString:@" histogram\n"];
                break;
            default:
            case UMPrometheusMetricType_counter:
                [s appendString:@" counter\n"];
                break;
        }
    }
    [self update];
    [s appendFormat:@"%@ %@\n",key,self.value];
    [_lock unlock];
    return s;
}

- (void)increaseBy:(NSInteger)inc
{
    [_lock lock];
    NSInteger i = [_value integerValue];
    i = i + inc;
    _value = @(i);
    [_lock unlock];
}

- (void)setSubname1:(NSString *)a value:(NSString *)b
{
    _subname1 = a;
    _subvalue1 = b;
}
@end

