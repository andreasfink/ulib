//
//  UMPrometheusThroughputMetric.h
//  ulib
//
//  Created by Andreas Fink on 18.06.21.
//  Copyright © 2021 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMPrometheusMetric.h"
#import "UMThroughputCounter.h"

@interface UMPrometheusThroughputMetric : UMPrometheusMetric
{
    UMThroughputCounter *_throughputCounter;
    double _reportDuration;
}

- (UMPrometheusThroughputMetric *)initWithResolutionInSeconds:(double)resolution
                                               reportDuration:(double) duration;

@end
