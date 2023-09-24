//
//  UMPrometheusThroughputMetric.h
//  ulib
//
//  Created by Andreas Fink on 18.06.21.
//  Copyright © 2021 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMPrometheusMetric.h>
#import <ulib/UMThroughputCounter.h>

@interface UMPrometheusThroughputMetric : UMPrometheusMetric
{
    UMThroughputCounter *_throughputCounter;
    double _reportDuration;
}

- (UMPrometheusThroughputMetric *)initWithResolutionInSeconds:(double)resolution
                                               reportDuration:(double) duration;

- (UMPrometheusThroughputMetric *)initWithResolutionInSeconds:(double)resolution
                                               reportDuration:(double) duration
                                                         name:(NSString *)name
                                                     subname1:(NSString *)sub1
                                                    subvalue1:(NSString *)val1;
@end
