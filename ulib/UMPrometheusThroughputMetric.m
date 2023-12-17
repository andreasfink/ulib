//
//  UMPrometheusThroughputMetric.m
//  ulib
//
//  Created by Andreas Fink on 18.06.21.
//  Copyright © 2021 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMPrometheusThroughputMetric.h>

@implementation UMPrometheusThroughputMetric


- (UMPrometheusThroughputMetric *)init
{
    self = [super init];
    {
        _throughputCounter = [[UMThroughputCounter alloc] initWithResolutionInSeconds: 0.1 maxDuration: 3.0];
        _reportDuration = 3.0;
        _metricType = UMPrometheusMetricType_gauge;
    }
    return self;
}


- (UMPrometheusThroughputMetric *)initWithResolutionInSeconds:(double)resolution
                                               reportDuration:(double) duration
{
    self = [super init];
    {
        _throughputCounter = [[UMThroughputCounter alloc]initWithResolutionInSeconds:resolution maxDuration:duration];
        _reportDuration = duration;
    }
    return self;
}

- (UMPrometheusThroughputMetric *)initWithResolutionInSeconds:(double)resolution
                                               reportDuration:(double) duration
                                                         name:(NSString *)name
                                                     subname1:(NSString *)sub1
                                                    subvalue1:(NSString *)val1;
{
    self = [super initWithMetricName:name subname1:sub1 subvalue1:val1 type:UMPrometheusMetricType_gauge];
    {
        _throughputCounter = [[UMThroughputCounter alloc]initWithResolutionInSeconds:resolution maxDuration:duration];
        _reportDuration = duration;
    }
    return self;

}

- (void)increaseBy:(NSInteger)i
{
    [_throughputCounter increaseBy:(uint32_t)i];
}

- (NSNumber *)value
{
    double speed =  [_throughputCounter getSpeedForSeconds:_reportDuration];
    return @(speed);
}

@end
