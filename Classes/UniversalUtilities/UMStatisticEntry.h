//
//  UMStatisticEntry.h
//  ulib
//
//  Created by Andreas Fink on 08.07.19.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"
#import "UMMutex.h"
#import "UMThroughputCounter.h"


#define UMSTATISTIC_SECONDS_MAX 3600
#define UMSTATISTIC_MINUTES_MAX 2880
#define UMSTATISTIC_HOURS_MAX 1488
#define UMSTATISTIC_DAYS_MAX 1460
#define UMSTATISTIC_WEEKS_MAX 530
#define UMSTATISTIC_MONTHS_MAX 120
#define UMSTATISTIC_YEARS_MAX 10

typedef double um_statistic_counter_type;

@class UMSynchronizedSortedDictionary;


@interface UMStatisticEntry : UMObject
{
    NSString *_name;
    UMMutex *_lock;

    long long   _currentSecondsIndex;
    long long   _secondsIndex;
    long long   _secondsEndIndex;


    NSInteger   _currentMinutesIndex;
    NSInteger   _minutesIndex;
    NSInteger   _minutesEndIndex;

    NSInteger   _currentHoursIndex;
    NSInteger   _hoursIndex;
    NSInteger   _hoursEndIndex;

    NSInteger   _currentDaysIndex;
    NSInteger   _daysIndex;
    NSInteger   _daysEndIndex;


    NSInteger   _currentWeeksIndex;
    NSInteger   _weeksIndex;
    NSInteger   _weeksEndIndex;

    NSInteger   _currentMonthsIndex;
    NSInteger   _monthsIndex;
    NSInteger   _monthsEndIndex;


    NSInteger   _currentYearsIndex;
    NSInteger   _yearsIndex;
    NSInteger   _yearsEndIndex;

    um_statistic_counter_type      _secondsData[UMSTATISTIC_SECONDS_MAX];
    um_statistic_counter_type      _secondsDataMax[UMSTATISTIC_SECONDS_MAX];
    um_statistic_counter_type      _secondsDataMin[UMSTATISTIC_SECONDS_MAX];
    long                           _secondsDataCount[UMSTATISTIC_SECONDS_MAX];
    um_statistic_counter_type      _minutesData[UMSTATISTIC_MINUTES_MAX];
    um_statistic_counter_type      _minutesDataMax[UMSTATISTIC_MINUTES_MAX];
    um_statistic_counter_type      _minutesDataMin[UMSTATISTIC_MINUTES_MAX];
    long                           _minutesDataCount[UMSTATISTIC_MINUTES_MAX];
    um_statistic_counter_type      _hoursData[UMSTATISTIC_HOURS_MAX];
    um_statistic_counter_type      _hoursDataMax[UMSTATISTIC_HOURS_MAX];
    um_statistic_counter_type      _hoursDataMin[UMSTATISTIC_HOURS_MAX];
    long                           _hoursDataCount[UMSTATISTIC_HOURS_MAX];
    um_statistic_counter_type      _daysData[UMSTATISTIC_DAYS_MAX];
    um_statistic_counter_type      _daysDataMax[UMSTATISTIC_DAYS_MAX];
    um_statistic_counter_type      _daysDataMin[UMSTATISTIC_DAYS_MAX];
    long                           _daysDataCount[UMSTATISTIC_DAYS_MAX];
    um_statistic_counter_type      _weeksData[UMSTATISTIC_WEEKS_MAX];
    um_statistic_counter_type      _weeksDataMax[UMSTATISTIC_WEEKS_MAX];
    um_statistic_counter_type      _weeksDataMin[UMSTATISTIC_WEEKS_MAX];
    long                           _weeksDataCount[UMSTATISTIC_WEEKS_MAX];
    um_statistic_counter_type      _monthsData[UMSTATISTIC_MONTHS_MAX];
    um_statistic_counter_type      _monthsDataMax[UMSTATISTIC_MONTHS_MAX];
    um_statistic_counter_type      _monthsDataMin[UMSTATISTIC_MONTHS_MAX];
    long                           _monthsDataCount[UMSTATISTIC_MONTHS_MAX];
    um_statistic_counter_type      _yearsData[UMSTATISTIC_YEARS_MAX];
    um_statistic_counter_type      _yearsDataMax[UMSTATISTIC_YEARS_MAX];
    um_statistic_counter_type      _yearsDataMin[UMSTATISTIC_YEARS_MAX];
    long                           _yearsDataCount[UMSTATISTIC_YEARS_MAX];
}


@property(readwrite,strong,atomic)  NSString *name;

- (UMStatisticEntry *)initWithDictionary:(NSDictionary *)dict;

- (void)increaseBy:(double)count;

- (void)setDictionaryValue:(NSDictionary *)dict;
- (UMSynchronizedSortedDictionary *)dictionaryValue;


@end

