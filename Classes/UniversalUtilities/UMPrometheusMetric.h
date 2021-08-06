//
//  UMPrometheusMetric.h
//  mm
//
//  Created by Andreas Fink on 27.05.21.
//

#import "UMObject.h"

@class UMPrometheusMetric;
@class UMPrometheus;

@protocol UMPrometheusDataSourceProtocol
-(void)updatePrometheusData:(UMPrometheusMetric *)metric;
@end

typedef enum UMPrometheusMetricType
{
    UMPrometheusMetricType_counter = 0,
    UMPrometheusMetricType_gauge = 1,
    UMPrometheusMetricType_histogram = 2,
} UMPrometheusMetricType;

@interface UMPrometheusMetric : UMObject
{
    UMMutex *_lock;
    UMPrometheus *_parent;
    NSString *_metricName;
    NSString *_subname1;
    NSString *_subvalue1;
    NSString *_subname2;
    NSString *_subvalue2;
    NSString *_subname3;
    NSString *_subvalue3;
    NSString *_help;
    UMPrometheusMetricType _metricType;
    NSNumber *_value;
    NSDate *_timestamp;
    id<UMPrometheusDataSourceProtocol> _delegate;
}

@property(readwrite,strong) UMPrometheus *parent;
@property(readwrite,strong) NSString *metricName;
@property(readwrite,strong) NSString *subname1;
@property(readwrite,strong) NSString *subvalue1;
@property(readwrite,strong) NSString *subname2;
@property(readwrite,strong) NSString *subvalue2;
@property(readwrite,strong) NSString *subname3;
@property(readwrite,strong) NSString *subvalue3;
@property(readwrite,strong) NSString *help;
@property(readwrite,assign) UMPrometheusMetricType metricType;
@property(readwrite,strong) NSNumber *value;
@property(readwrite,strong) NSDate *timestamp;
@property(readwrite,strong) id<UMPrometheusDataSourceProtocol> delegate;


- (UMPrometheusMetric *)initWithMetricName:(NSString *)name
                                      type:(UMPrometheusMetricType)t;

- (UMPrometheusMetric *)initWithMetricName:(NSString *)name
                                  subname1:(NSString *)sub1
                                 subvalue1:(NSString *)val1
                                      type:(UMPrometheusMetricType)t;

- (UMPrometheusMetric *)initWithMetricName:(NSString *)name
                                  subname1:(NSString *)sub1
                                 subvalue1:(NSString *)val1
                                  subname2:(NSString *)sub1
                                 subvalue2:(NSString *)val1
                                      type:(UMPrometheusMetricType)t;

- (NSString *)prometheusOutputHelp;
- (NSString *)prometheusOutputType;
- (NSString *)prometheusOutputData;

- (void)updatePrometheusData:(UMPrometheusMetric *)metric;
- (void)update;
- (NSString *)key;
- (void)increaseBy:(NSInteger)i;
- (void)setSubname1:(NSString *)a value:(NSString *)b;
@end

