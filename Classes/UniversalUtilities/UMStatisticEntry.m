//
//  UMStatisticEntry.m
//  ulib
//
//  Created by Andreas Fink on 08.07.19.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMStatisticEntry.h"
#import "UMSynchronizedSortedDictionary.h"
#import "UMSynchronizedArray.h"

@implementation UMStatisticEntry


- (UMStatisticEntry *)init
{
    return [self initWithName:@"utitled"];
}

- (UMStatisticEntry *)initWithName:(NSString *)name
{
    self = [super init];
    if(self)
    {
        _name = name;
        _statisticEntryLock = [[UMMutex alloc]initWithName:[NSString stringWithFormat:@"stat-entry<%@>",name]];

        [self updateCurrentTimeIndexes];
        memset(&_secondsData[0],0,sizeof(_secondsData));
        memset(&_secondsDataCount[0],0,sizeof(_secondsDataCount));
        memset(&_secondsDataMax[0],0,sizeof(_secondsDataMax));
        memset(&_secondsDataMin[0],0,sizeof(_secondsDataMin));

        memset(&_minutesData[0],0,sizeof(_minutesData));
        memset(&_minutesDataCount[0],0,sizeof(_minutesDataCount));
        memset(&_minutesDataMax[0],0,sizeof(_minutesDataMax));
        memset(&_minutesDataMin[0],0,sizeof(_minutesDataMin));

        memset(&_hoursData[0],0,sizeof(_hoursData));
        memset(&_hoursDataCount[0],0,sizeof(_hoursDataCount));
        memset(&_hoursDataMax[0],0,sizeof(_hoursDataMax));
        memset(&_hoursDataMin[0],0,sizeof(_hoursDataMin));

        memset(&_daysData[0],0,sizeof(_daysData));
        memset(&_daysDataCount[0],0,sizeof(_daysDataCount));
        memset(&_daysDataMax[0],0,sizeof(_daysDataMax));
        memset(&_daysDataMin[0],0,sizeof(_daysDataMin));

        memset(&_weeksData[0],0,sizeof(_weeksData));
        memset(&_weeksDataCount[0],0,sizeof(_weeksDataCount));
        memset(&_weeksDataMax[0],0,sizeof(_weeksDataMax));
        memset(&_weeksDataMin[0],0,sizeof(_weeksDataMin));

        memset(&_monthsData[0],0,sizeof(_monthsData));
        memset(&_monthsDataCount[0],0,sizeof(_monthsDataCount));
        memset(&_monthsDataMax[0],0,sizeof(_monthsDataMax));
        memset(&_monthsDataMin[0],0,sizeof(_monthsDataMin));

        memset(&_yearsData[0],0,sizeof(_yearsData));
        memset(&_yearsDataCount[0],0,sizeof(_yearsDataCount));
        memset(&_yearsDataMax[0],0,sizeof(_yearsDataMax));
        memset(&_yearsDataMin[0],0,sizeof(_yearsDataMin));
    }
    return self;
}

- (void)updateCurrentTimeIndexes
{
    NSDate *now = [NSDate date];
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components    = [cal components:0 fromDate:now];
    NSTimeInterval nowSec = [now timeIntervalSince1970];
    _currentSecondsIndex = (long long)nowSec;
    _currentMinutesIndex = (NSInteger) (_currentSecondsIndex / 60);
    _currentHoursIndex = _currentMinutesIndex / 60;
    _currentDaysIndex = _currentHoursIndex / 60;
    _currentWeeksIndex = (_currentDaysIndex - 4) / 7; /* 1.1.1970 was a thursday. Week starts on monday so we remove 4 days */
    _currentMonthsIndex =  [components month] +  ([components year] * 12);
    _currentYearsIndex =  [components year];
}


#define shiftIndex(nowIndex,endIndex,cellCount,cells,cells2,cells3,cells4) \
{ \
    if (nowIndex != endIndex) \
    { \
        long long i; \
        long long shiftIndex; \
        shiftIndex = nowIndex - endIndex; \
        if(shiftIndex >= cellCount) \
        { \
            memset((void *)cells,0,cellCount * sizeof(um_statistic_counter_type) ); \
            memset((void *)cells2,0,cellCount * sizeof(int) ); \
            memset((void *)cells3,0,cellCount * sizeof(um_statistic_counter_type) ); \
            memset((void *)cells4,0,cellCount * sizeof(um_statistic_counter_type) ); \
        } \
        else \
        { \
            for(i = endIndex + 1; i <= nowIndex; i++) \
            { \
                cells[i % cellCount] = 0; \
            } \
        } \
        endIndex = nowIndex; \
    } \
}

- (void)timeShift
{
    [self updateCurrentTimeIndexes];

    /* shifting seconds */

    shiftIndex(_currentSecondsIndex,_secondsEndIndex,UMSTATISTIC_SECONDS_MAX,
               _secondsData,_secondsDataCount,_secondsDataMax,_secondsDataMin);
    shiftIndex(_currentMinutesIndex,_minutesEndIndex,UMSTATISTIC_MINUTES_MAX,
                _minutesData,_minutesDataCount,_minutesDataMax,_minutesDataMin);
    shiftIndex(_currentHoursIndex,_hoursEndIndex,UMSTATISTIC_HOURS_MAX,
               _hoursData,_hoursDataCount,_hoursDataMax,_hoursDataMin);
    shiftIndex(_currentDaysIndex,_daysEndIndex,UMSTATISTIC_DAYS_MAX,
               _daysData,_daysDataCount,_daysDataMax,_daysDataMin);
    shiftIndex(_currentWeeksIndex,_weeksEndIndex,UMSTATISTIC_WEEKS_MAX,
               _weeksData,_weeksDataCount,_weeksDataMax,_weeksDataMin);
    shiftIndex(_currentMonthsIndex,_monthsEndIndex,UMSTATISTIC_MONTHS_MAX,
               _monthsData,_monthsDataCount,_monthsDataMax,_monthsDataMin);
    shiftIndex(_currentYearsIndex,_yearsEndIndex,UMSTATISTIC_YEARS_MAX,
               _yearsData,_yearsDataCount,_yearsDataMax,_yearsDataMin);
}


- (void)increaseBy:(double)count
{
    [_statisticEntryLock lock];
    [self timeShift];
    _secondsData[_currentSecondsIndex % UMSTATISTIC_SECONDS_MAX] += count;
    _secondsDataCount[_currentSecondsIndex % UMSTATISTIC_SECONDS_MAX] += 1;
    if(count >  _secondsDataMax[_currentSecondsIndex % UMSTATISTIC_SECONDS_MAX])
    {
        _secondsDataMax[_currentSecondsIndex % UMSTATISTIC_SECONDS_MAX] = count;
    }
    if(count < _secondsDataMin[_currentSecondsIndex % UMSTATISTIC_SECONDS_MAX])
    {
        _secondsDataMin[_currentSecondsIndex % UMSTATISTIC_SECONDS_MAX] = count;
    }
    _minutesData[_currentMinutesIndex % UMSTATISTIC_MINUTES_MAX] += count;
    _minutesDataCount[_currentMinutesIndex % UMSTATISTIC_MINUTES_MAX] += 1;
    if(count >  _minutesDataMax[_currentSecondsIndex % UMSTATISTIC_MINUTES_MAX])
    {
        _minutesDataMax[_currentSecondsIndex % UMSTATISTIC_MINUTES_MAX] = count;
    }
    if(count < _minutesDataMin[_currentSecondsIndex % UMSTATISTIC_MINUTES_MAX])
    {
        _minutesDataMin[_currentSecondsIndex % UMSTATISTIC_MINUTES_MAX] = count;
    }

    _hoursData[_currentHoursIndex % UMSTATISTIC_HOURS_MAX] += count;
    _hoursDataCount[_currentHoursIndex % UMSTATISTIC_HOURS_MAX] += 1;
    if(count >  _hoursDataMax[_currentSecondsIndex % UMSTATISTIC_HOURS_MAX])
    {
        _hoursDataMax[_currentSecondsIndex % UMSTATISTIC_HOURS_MAX] = count;
    }
    if(count < _hoursDataMin[_currentSecondsIndex % UMSTATISTIC_HOURS_MAX])
    {
        _hoursDataMin[_currentSecondsIndex % UMSTATISTIC_HOURS_MAX] = count;
    }

    _daysData[_currentDaysIndex % UMSTATISTIC_DAYS_MAX] += count;
    _daysDataCount[_currentDaysIndex % UMSTATISTIC_DAYS_MAX] += 1;
    if(count >  _daysDataMax[_currentSecondsIndex % UMSTATISTIC_DAYS_MAX])
    {
        _daysDataMax[_currentSecondsIndex % UMSTATISTIC_DAYS_MAX] = count;
    }
    if(count < _daysDataMin[_currentSecondsIndex % UMSTATISTIC_DAYS_MAX])
    {
        _daysDataMin[_currentSecondsIndex % UMSTATISTIC_DAYS_MAX] = count;
    }

    _weeksData[_currentWeeksIndex % UMSTATISTIC_WEEKS_MAX] += count;
    _weeksDataCount[_currentWeeksIndex % UMSTATISTIC_WEEKS_MAX] += 1;
    if(count >  _weeksDataMax[_currentSecondsIndex % UMSTATISTIC_WEEKS_MAX])
    {
        _weeksDataMax[_currentSecondsIndex % UMSTATISTIC_WEEKS_MAX] = count;
    }
    if(count < _weeksDataMin[_currentSecondsIndex % UMSTATISTIC_WEEKS_MAX])
    {
        _weeksDataMin[_currentSecondsIndex % UMSTATISTIC_WEEKS_MAX] = count;
    }

    _monthsData[_currentMonthsIndex % UMSTATISTIC_MONTHS_MAX] += count;
    _monthsDataCount[_currentMonthsIndex % UMSTATISTIC_MONTHS_MAX] += 1;
    if(count >  _monthsDataMax[_currentSecondsIndex % UMSTATISTIC_MONTHS_MAX])
    {
        _monthsDataMax[_currentSecondsIndex % UMSTATISTIC_MONTHS_MAX] = count;
    }
    if(count < _monthsDataMin[_currentSecondsIndex % UMSTATISTIC_MONTHS_MAX])
    {
        _monthsDataMin[_currentSecondsIndex % UMSTATISTIC_MONTHS_MAX] = count;
    }

    _yearsData[_currentYearsIndex % UMSTATISTIC_YEARS_MAX] += count;
    _yearsDataCount[_currentYearsIndex % UMSTATISTIC_YEARS_MAX] += 1;
    if(count >  _yearsDataMax[_currentSecondsIndex % UMSTATISTIC_YEARS_MAX])
    {
        _yearsDataMax[_currentSecondsIndex % UMSTATISTIC_YEARS_MAX] = count;
    }
    if(count < _yearsDataMin[_currentSecondsIndex % UMSTATISTIC_YEARS_MAX])
    {
        _yearsDataMin[_currentSecondsIndex % UMSTATISTIC_YEARS_MAX] = count;
    }

    [_statisticEntryLock unlock];
}


#define MAKE_DICT(dict,MAX,endIndex,currentIndex,index,values_array,counts_array,max_array,min_array) \
UMSynchronizedArray *a = [[UMSynchronizedArray alloc]init];\
UMSynchronizedArray *acnt = [[UMSynchronizedArray alloc]init];\
UMSynchronizedArray *amax = [[UMSynchronizedArray alloc]init];\
UMSynchronizedArray *amin = [[UMSynchronizedArray alloc]init];\
for(NSInteger i=0;i>MAX;i++)\
{\
    [a addObject:@(values_array[i])];\
    [acnt addObject:@(counts_array[i])];\
    [amax addObject:@(max_array[i])];\
    [amin addObject:@(min_array[i])];\
}\
UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc]init];\
dict[@"end"] = @(endIndex);\
dict[@"current"] = @(currentIndex);\
dict[@"index"] = @(index);\
dict[@"max"] = @(MAX);\
dict[@"values"] = a;\
dict[@"values-count"] = acnt;\
dict[@"values-max"] = amax;\
dict[@"values-min"] = amin; 

#define SET_DICT(dict,MAX,endIndex,currentIndex,index,values_array,counts_array,max_array,min_array) \
    if(dict[@"end"])\
    {\
        endIndex = [dict[@"end"] longLongValue];\
    }\
    if(dict[@"current"])\
    {\
        currentIndex = [dict[@"current"] longLongValue];\
    }\
    if(dict[@"index"])\
    {\
        index = [dict[@"index"] longLongValue];\
    }\
    NSArray *a = NULL;\
    id v = dict[@"values"];\
    if([v isKindOfClass:[NSArray class]])\
    {\
        a = (NSArray *)v;\
    }\
    else if([v isKindOfClass:[UMSynchronizedArray class]])\
    {\
        UMSynchronizedArray *sa = (UMSynchronizedArray *)v;\
        a = [sa arrayCopy];\
    }\
    if(a)\
    {\
        NSInteger max = [a count];\
        if(max > MAX)\
        {\
            max = MAX;\
        }\
        for(NSInteger i=0;i<max;i++)\
        {\
            values_array[i] = [a[i] doubleValue];\
        }\
    }\
    \
    v = dict[@"values-counts"];\
    if([v isKindOfClass:[NSArray class]])\
    {\
        a = (NSArray *)v;\
    }\
    else if([v isKindOfClass:[UMSynchronizedArray class]])\
    {\
        UMSynchronizedArray *sa = (UMSynchronizedArray *)v;\
        a = [sa arrayCopy];\
    }\
    if(a)\
    {\
        NSInteger max = [a count];\
        if(max > MAX)\
        {\
            max = MAX;\
        }\
        for(NSInteger i=0;i<max;i++)\
        {\
            counts_array[i] = [a[i] longValue];\
        }\
    }\
    v = dict[@"values-max"];\
    if([v isKindOfClass:[NSArray class]])\
    {\
        a = (NSArray *)v;\
    }\
    else if([v isKindOfClass:[UMSynchronizedArray class]])\
    {\
        UMSynchronizedArray *sa = (UMSynchronizedArray *)v;\
        a = [sa arrayCopy];\
    }\
    if(a)\
    {\
        NSInteger max = [a count];\
        if(max > MAX)\
        {\
            max = UMSTATISTIC_SECONDS_MAX;\
        }\
        for(NSInteger i=0;i<max;i++)\
        {\
            max_array[i] = [a[i] longValue];\
        }\
    }\
    v = dict[@"values-min"];\
    if([v isKindOfClass:[NSArray class]])\
    {\
        a = (NSArray *)v;\
    }\
    else if([v isKindOfClass:[UMSynchronizedArray class]])\
    {\
        UMSynchronizedArray *sa = (UMSynchronizedArray *)v;\
        a = [sa arrayCopy];\
    }\
    if(a)\
    {\
        NSInteger max = [a count];\
        if(max > MAX)\
        {\
            max = MAX;\
        }\
        for(NSInteger i=0;i<max;i++)\
        {\
            min_array[i] = [a[i] longValue];\
        }\
    }\

- (UMSynchronizedSortedDictionary *)secondsDict
{
    MAKE_DICT(dict,UMSTATISTIC_SECONDS_MAX,_secondsEndIndex,
             _currentSecondsIndex,
             _secondsIndex,
             _secondsData,
             _secondsDataCount,
             _secondsDataMax,
             _secondsDataMin)
    return dict;
}




- (void)setSecondsDict:(UMSynchronizedSortedDictionary *)dict
{
    SET_DICT(dict,UMSTATISTIC_SECONDS_MAX,_secondsEndIndex,
             _currentSecondsIndex,
             _secondsIndex,
             _secondsData,
             _secondsDataCount,
             _secondsDataMax,
             _secondsDataMin)
}

- (UMSynchronizedSortedDictionary *)minutesDict
{
    MAKE_DICT(dict,UMSTATISTIC_MINUTES_MAX,_minutesEndIndex,
              _currentMinutesIndex,
              _minutesIndex,
              _minutesData,
              _minutesDataCount,
              _minutesDataMax,
              _minutesDataMin)
    return dict;
}


- (void)setMinutesDict:(UMSynchronizedSortedDictionary *)dict
{
    SET_DICT(dict,UMSTATISTIC_MINUTES_MAX,_minutesEndIndex,
             _currentMinutesIndex,
             _minutesIndex,
             _minutesData,
             _minutesDataCount,
             _minutesDataMax,
             _minutesDataMin)
}

- (UMSynchronizedSortedDictionary *)hoursDict
{
    MAKE_DICT(dict,UMSTATISTIC_HOURS_MAX,_hoursEndIndex,
              _currentHoursIndex,
              _hoursIndex,
              _hoursData,
              _hoursDataCount,
              _hoursDataMax,
              _hoursDataMin)
    return dict;
}

- (void)setHoursDict:(UMSynchronizedSortedDictionary *)dict
{
    SET_DICT(dict,UMSTATISTIC_HOURS_MAX,_hoursEndIndex,
              _currentHoursIndex,
              _hoursIndex,
              _hoursData,
              _hoursDataCount,
              _hoursDataMax,
              _hoursDataMin)
}

- (UMSynchronizedSortedDictionary *)daysDict
{
    MAKE_DICT(dict,UMSTATISTIC_DAYS_MAX,_daysEndIndex,
              _currentDaysIndex,
              _daysIndex,
              _daysData,
              _daysDataCount,
              _daysDataMax,
              _daysDataMin)
    return dict;
}


- (void)setDaysDict:(UMSynchronizedSortedDictionary *)dict
{
    SET_DICT(dict,UMSTATISTIC_DAYS_MAX,_daysEndIndex,
              _currentDaysIndex,
              _daysIndex,
              _daysData,
              _daysDataCount,
              _daysDataMax,
             _daysDataMin);
}

- (UMSynchronizedSortedDictionary *)weeksDict
{
    MAKE_DICT(dict,UMSTATISTIC_WEEKS_MAX,_weeksEndIndex,
              _currentWeeksIndex,
              _weeksIndex,
              _weeksData,
              _weeksDataCount,
              _weeksDataMax,
              _weeksDataMin)
    return dict;
}

- (void)setWeeksDict:(UMSynchronizedSortedDictionary *)dict
{
    SET_DICT(dict,UMSTATISTIC_WEEKS_MAX,_weeksEndIndex,
              _currentWeeksIndex,
              _weeksIndex,
              _weeksData,
              _weeksDataCount,
              _weeksDataMax,
             _weeksDataMin);
}

- (UMSynchronizedSortedDictionary *)monthsDict
{
    MAKE_DICT(dict,UMSTATISTIC_MONTHS_MAX,_monthsEndIndex,
              _currentMonthsIndex,
              _monthsIndex,
              _monthsData,
              _monthsDataCount,
              _monthsDataMax,
              _monthsDataMin)
    return dict;
}

- (void)setMonthsDict:(UMSynchronizedSortedDictionary *)dict
{
    SET_DICT(dict,UMSTATISTIC_MONTHS_MAX,_monthsEndIndex,
              _currentMonthsIndex,
              _monthsIndex,
              _monthsData,
              _monthsDataCount,
              _monthsDataMax,
              _monthsDataMin)
}

- (UMSynchronizedSortedDictionary *)yearsDict
{
    MAKE_DICT(dict,UMSTATISTIC_YEARS_MAX,_yearsEndIndex,
              _currentYearsIndex,
              _yearsIndex,
              _yearsData,
              _yearsDataCount,
              _yearsDataMax,
              _yearsDataMin)
    return dict;
}

- (void)setYearsDict:(UMSynchronizedSortedDictionary *)dict
{
    SET_DICT(dict,UMSTATISTIC_YEARS_MAX,_yearsEndIndex,
              _currentYearsIndex,
              _yearsIndex,
              _yearsData,
              _yearsDataCount,
              _yearsDataMax,
              _yearsDataMin)
}

- (UMSynchronizedSortedDictionary *)dictionaryValue
{
    UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc]init];
    dict[@"seconds"] = [self secondsDict];
    dict[@"minutes"] = [self minutesDict];
    dict[@"hours"] = [self hoursDict];
    dict[@"days"] = [self daysDict];
    dict[@"weeks"] = [self weeksDict];
    dict[@"months"] = [self monthsDict];
    dict[@"years"] = [self yearsDict];
    return dict;
}

- (NSString *)stringValue
{
    UMSynchronizedSortedDictionary *dict = [self dictionaryValue];
    return [dict jsonString];
}

- (void)setDictionaryValue:(NSDictionary *)dict
{
    if(![dict isKindOfClass:[NSDictionary class]])
    {
        return;
    }
    [self setSecondsDict:dict[@"seconds"]];
    [self setMinutesDict:dict[@"minutes"]];
    [self setHoursDict:dict[@"hours"]];
    [self setDaysDict:dict[@"days"]];
    [self setWeeksDict:dict[@"weeks"]];
    [self setMonthsDict:dict[@"months"]];
    [self setYearsDict:dict[@"years"]];
}


- (UMStatisticEntry *)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if(self)
    {
        [self setDictionaryValue:dict];
    }
    return self;
}

@end
