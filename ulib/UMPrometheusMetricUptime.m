//
//  UMPrometheusMetricUptime.m
//  ulib
//
//  Created by Andreas Fink on 30.06.21.
//  Copyright © 2021 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMPrometheusMetricUptime.h>

@implementation UMPrometheusMetricUptime

-(UMPrometheusMetricUptime *)init
{
    self = [super init];
    if(self)
    {
        _startTime = [NSDate date];
        _metricName = @"uptime";
        _metricType = UMPrometheusMetricType_counter;
        _help = @"Seconds since startup";
        _value =@(0.0);
    }
    return self;
}

-(void)updatePrometheusData:(UMPrometheusMetric *)metric;
{
    NSDate *now = [NSDate date];
    NSTimeInterval delay = [now timeIntervalSinceDate:_startTime];
    _value = @(delay);
}

@end
