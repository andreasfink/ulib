//
//  UMPrometheusMetricUptime.h
//  ulib
//
//  Created by Andreas Fink on 30.06.21.
//  Copyright © 2021 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMPrometheusMetric.h"

@interface UMPrometheusMetricUptime : UMPrometheusMetric
{
    NSDate  *_startTime;
}

@end
