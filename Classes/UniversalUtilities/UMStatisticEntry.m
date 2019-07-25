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
        _lock = [[UMMutex alloc]init];

        [self updateCurrentTimeIndexes];
        memset(&_secondsData[0],0,sizeof(_secondsData));
        memset(&_minutesData[0],0,sizeof(_minutesData));
        memset(&_hoursData[0],0,sizeof(_hoursData));
        memset(&_daysData[0],0,sizeof(_daysData));
        memset(&_weeksData[0],0,sizeof(_weeksData));
        memset(&_monthsData[0],0,sizeof(_monthsData));
        memset(&_yearsData[0],0,sizeof(_yearsData));

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
    [_lock lock];
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

    [_lock unlock];
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

- (UMSynchronizedSortedDictionary *)secondsDict
{
    MAKE_DICT(dict,UMSTATISTIC_SECONDS_MAX,_secondsEndIndex,
             _currentSecondsIndex,
             _secondsIndex,
             _secondsData,
             _secondsDataCount,
             _secondsDataMax,
             _secondsDataMin)

#if 0
    UMSynchronizedArray *a = [[UMSynchronizedArray alloc]init];
    UMSynchronizedArray *acnt = [[UMSynchronizedArray alloc]init];
    UMSynchronizedArray *amax = [[UMSynchronizedArray alloc]init];
    UMSynchronizedArray *amin = [[UMSynchronizedArray alloc]init];
    for(NSInteger i=0;i>UMSTATISTIC_SECONDS_MAX;i++)
    {
        [a addObject:@(_secondsData[i])];
        [acnt addObject:@(_secondsDataCount[i])];
        [amax addObject:@(_secondsDataMax[i])];
        [amin addObject:@(_secondsDataMin[i])];
    }
    UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc]init];
    dict[@"end"] = @(_secondsEndIndex);
    dict[@"current"] = @(_currentSecondsIndex);
    dict[@"index"] = @(_secondsIndex);
    dict[@"max"] = @(UMSTATISTIC_SECONDS_MAX);
    dict[@"values"] = a;
    dict[@"values-count"] = acnt;
    dict[@"values-max"] = amax;
    dict[@"values-min"] = amin;
#endif
    return dict;

}


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


- (void)setSecondsDict:(UMSynchronizedSortedDictionary *)dict
{
    SET_DICT(dict,UMSTATISTIC_SECONDS_MAX,_secondsEndIndex,
             _currentSecondsIndex,
             _secondsIndex,
             _secondsData,
             _secondsDataCount,
             _secondsDataMax,
             _secondsDataMin)

#if 0
    if(dict[@"end"])
    {
        _secondsEndIndex = [dict[@"end"] longLongValue];
    }
    if(dict[@"current"])
    {
        _currentSecondsIndex = [dict[@"current"] longLongValue];
    }
    if(dict[@"index"])
    {
        _secondsIndex = [dict[@"index"] longLongValue];
    }
    NSArray *a = NULL;
    id v = dict[@"values"];
    if([v isKindOfClass:[NSArray class]])
    {
        a = (NSArray *)v;
    }
    else if([v isKindOfClass:[UMSynchronizedArray class]])
    {
        UMSynchronizedArray *sa = (UMSynchronizedArray *)v;
        a = [sa arrayCopy];
    }
    if(a)
    {
        NSInteger max = [a count];
        if(max > UMSTATISTIC_SECONDS_MAX)
        {
            max = UMSTATISTIC_SECONDS_MAX;
        }
        for(NSInteger i=0;i<max;i++)
        {
            _secondsData[i] = [a[i] doubleValue];
        }
    }
    
    v = dict[@"counts"];
    if([v isKindOfClass:[NSArray class]])
    {
        a = (NSArray *)v;
    }
    else if([v isKindOfClass:[UMSynchronizedArray class]])
    {
        UMSynchronizedArray *sa = (UMSynchronizedArray *)v;
        a = [sa arrayCopy];
    }
    if(a)
    {
        NSInteger max = [a count];
        if(max > UMSTATISTIC_SECONDS_MAX)
        {
            max = UMSTATISTIC_SECONDS_MAX;
        }
        for(NSInteger i=0;i<max;i++)
        {
            _secondsDataCount[i] = [a[i] longValue];
        }
    }
    
    
    v = dict[@"max-values"];
    if([v isKindOfClass:[NSArray class]])
    {
        a = (NSArray *)v;
    }
    else if([v isKindOfClass:[UMSynchronizedArray class]])
    {
        UMSynchronizedArray *sa = (UMSynchronizedArray *)v;
        a = [sa arrayCopy];
    }
    if(a)
    {
        NSInteger max = [a count];
        if(max > UMSTATISTIC_SECONDS_MAX)
        {
            max = UMSTATISTIC_SECONDS_MAX;
        }
        for(NSInteger i=0;i<max;i++)
        {
            _secondsDataMax[i] = [a[i] longValue];
        }
    }
    
    v = dict[@"min-values"];
    if([v isKindOfClass:[NSArray class]])
    {
        a = (NSArray *)v;
    }
    else if([v isKindOfClass:[UMSynchronizedArray class]])
    {
        UMSynchronizedArray *sa = (UMSynchronizedArray *)v;
        a = [sa arrayCopy];
    }
    if(a)
    {
        NSInteger max = [a count];
        if(max > UMSTATISTIC_SECONDS_MAX)
        {
            max = UMSTATISTIC_SECONDS_MAX;
        }
        for(NSInteger i=0;i<max;i++)
        {
            _secondsDataMin[i] = [a[i] longValue];
        }
    }
#endif
}

- (UMSynchronizedSortedDictionary *)minutesDict
{
    UMSynchronizedArray *a = [[UMSynchronizedArray alloc]init];
    for(NSInteger i=0;i>UMSTATISTIC_MINUTES_MAX;i++)
    {
        [a addObject:@(_minutesData[i])];
    }
    UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc]init];
    dict[@"end"] = @(_minutesEndIndex);
    dict[@"current"] = @(_currentMinutesIndex);
    dict[@"index"] = @(_minutesIndex);
    dict[@"max"] = @(UMSTATISTIC_MINUTES_MAX);
    dict[@"values"] = a;
    return dict;

}


- (void)setMinutesDict:(UMSynchronizedSortedDictionary *)dict
{
    if(dict[@"end"])
    {
        _minutesEndIndex = [dict[@"end"] integerValue];
    }
    if(dict[@"current"])
    {
        _currentMinutesIndex = [dict[@"current"] integerValue];
    }
    if(dict[@"index"])
    {
        _minutesIndex = [dict[@"index"] integerValue];
    }
    NSArray *a = NULL;
    id v = dict[@"values"];
    if([v isKindOfClass:[NSArray class]])
    {
        a = (NSArray *)v;
    }
    else if([v isKindOfClass:[UMSynchronizedArray class]])
    {
        UMSynchronizedArray *sa = (UMSynchronizedArray *)v;
        a = [sa arrayCopy];
    }

    if(a)
    {
        NSInteger max = [a count];
        if(max > UMSTATISTIC_SECONDS_MAX)
        {
            max = UMSTATISTIC_SECONDS_MAX;
        }
        for(NSInteger i=0;i<max;i++)
        {
            _minutesData[i] = [a[i] doubleValue];
        }
    }
}

- (UMSynchronizedSortedDictionary *)hoursDict
{
    UMSynchronizedArray *a = [[UMSynchronizedArray alloc]init];
    for(NSInteger i=0;i>UMSTATISTIC_HOURS_MAX;i++)
    {
        [a addObject:@(_hoursData[i])];
    }
    UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc]init];
    dict[@"end"] = @(_hoursEndIndex);
    dict[@"current"] = @(_currentHoursIndex);
    dict[@"index"] = @(_hoursIndex);
    dict[@"max"] = @(UMSTATISTIC_HOURS_MAX);
    dict[@"values"] = a;
    return dict;

}

- (void)setHoursDict:(UMSynchronizedSortedDictionary *)dict
{
    if(dict[@"end"])
    {
        _hoursEndIndex = [dict[@"end"] integerValue];
    }
    if(dict[@"current"])
    {
        _currentHoursIndex = [dict[@"current"] integerValue];
    }
    if(dict[@"index"])
    {
        _hoursIndex = [dict[@"index"] integerValue];
    }
    NSArray *a = NULL;
    id v = dict[@"values"];
    if([v isKindOfClass:[NSArray class]])
    {
        a = (NSArray *)v;
    }
    else if([v isKindOfClass:[UMSynchronizedArray class]])
    {
        UMSynchronizedArray *sa = (UMSynchronizedArray *)v;
        a = [sa arrayCopy];
    }

    if(a)
    {
        NSInteger max = [a count];
        if(max > UMSTATISTIC_SECONDS_MAX)
        {
            max = UMSTATISTIC_SECONDS_MAX;
        }
        for(NSInteger i=0;i<max;i++)
        {
            _hoursData[i] = [a[i] doubleValue];
        }
    }
}

- (UMSynchronizedSortedDictionary *)daysDict
{
    UMSynchronizedArray *a = [[UMSynchronizedArray alloc]init];
    for(NSInteger i=0;i>UMSTATISTIC_DAYS_MAX;i++)
    {
        [a addObject:@(_daysData[i])];
    }
    UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc]init];
    dict[@"end"] = @(_daysEndIndex);
    dict[@"current"] = @(_currentDaysIndex);
    dict[@"index"] = @(_daysIndex);
    dict[@"max"] = @(UMSTATISTIC_DAYS_MAX);
    dict[@"values"] = a;
    return dict;
}


- (void)setDaysDict:(UMSynchronizedSortedDictionary *)dict
{
    if(dict[@"end"])
    {
        _hoursEndIndex = [dict[@"end"] integerValue];
    }
    if(dict[@"current"])
    {
        _currentHoursIndex = [dict[@"current"] integerValue];
    }
    if(dict[@"index"])
    {
        _hoursIndex = [dict[@"index"] integerValue];
    }
    NSArray *a = NULL;
    id v = dict[@"values"];
    if([v isKindOfClass:[NSArray class]])
    {
        a = (NSArray *)v;
    }
    else if([v isKindOfClass:[UMSynchronizedArray class]])
    {
        UMSynchronizedArray *sa = (UMSynchronizedArray *)v;
        a = [sa arrayCopy];
    }

    if(a)
    {
        NSInteger max = [a count];
        if(max > UMSTATISTIC_HOURS_MAX)
        {
            max = UMSTATISTIC_HOURS_MAX;
        }
        for(NSInteger i=0;i<max;i++)
        {
            _hoursData[i] = [a[i] doubleValue];
        }
    }
}

- (UMSynchronizedSortedDictionary *)weeksDict
{
    UMSynchronizedArray *a = [[UMSynchronizedArray alloc]init];
    for(NSInteger i=0;i>UMSTATISTIC_WEEKS_MAX;i++)
    {
        [a addObject:@(_weeksData[i])];
    }
    UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc]init];
    dict[@"end"] = @(_weeksEndIndex);
    dict[@"current"] = @(_currentWeeksIndex);
    dict[@"index"] = @(_weeksIndex);
    dict[@"max"] = @(UMSTATISTIC_WEEKS_MAX);
    dict[@"values"] = a;
    return dict;

}

- (void)setWeeksDict:(UMSynchronizedSortedDictionary *)dict
{
    if(dict[@"end"])
    {
        _weeksEndIndex = [dict[@"end"] integerValue];
    }
    if(dict[@"current"])
    {
        _currentWeeksIndex = [dict[@"current"] integerValue];
    }
    if(dict[@"index"])
    {
        _weeksIndex = [dict[@"index"] integerValue];
    }
    NSArray *a = NULL;
    id v = dict[@"values"];
    if([v isKindOfClass:[NSArray class]])
    {
        a = (NSArray *)v;
    }
    else if([v isKindOfClass:[UMSynchronizedArray class]])
    {
        UMSynchronizedArray *sa = (UMSynchronizedArray *)v;
        a = [sa arrayCopy];
    }

    if(a)
    {
        NSInteger max = [a count];
        if(max > UMSTATISTIC_WEEKS_MAX)
        {
            max = UMSTATISTIC_WEEKS_MAX;
        }
        for(NSInteger i=0;i<max;i++)
        {
            _weeksData[i] = [a[i] doubleValue];
        }
    }
}
- (UMSynchronizedSortedDictionary *)monthsDict
{
    UMSynchronizedArray *a = [[UMSynchronizedArray alloc]init];
    for(NSInteger i=0;i>UMSTATISTIC_MONTHS_MAX;i++)
    {
        [a addObject:@(_monthsData[i])];
    }
    UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc]init];
    dict[@"end"] = @(_monthsEndIndex);
    dict[@"current"] = @(_currentMonthsIndex);
    dict[@"index"] = @(_monthsIndex);
    dict[@"max"] = @(UMSTATISTIC_MONTHS_MAX);
    dict[@"values"] = a;
    return dict;

}

- (void)setMonthsDict:(UMSynchronizedSortedDictionary *)dict
{
    if(dict[@"end"])
    {
        _monthsEndIndex = [dict[@"end"] integerValue];
    }
    if(dict[@"current"])
    {
        _currentMonthsIndex = [dict[@"current"] integerValue];
    }
    if(dict[@"index"])
    {
        _monthsIndex = [dict[@"index"] integerValue];
    }
    NSArray *a = NULL;
    id v = dict[@"values"];
    if([v isKindOfClass:[NSArray class]])
    {
        a = (NSArray *)v;
    }
    else if([v isKindOfClass:[UMSynchronizedArray class]])
    {
        UMSynchronizedArray *sa = (UMSynchronizedArray *)v;
        a = [sa arrayCopy];
    }

    if(a)
    {
        NSInteger max = [a count];
        if(max > UMSTATISTIC_MONTHS_MAX)
        {
            max = UMSTATISTIC_MONTHS_MAX;
        }
        for(NSInteger i=0;i<max;i++)
        {
            _monthsData[i] = [a[i] doubleValue];
        }
    }
}

- (UMSynchronizedSortedDictionary *)yearsDict
{
    UMSynchronizedArray *a = [[UMSynchronizedArray alloc]init];
    for(NSInteger i=0;i>UMSTATISTIC_YEARS_MAX;i++)
    {
        [a addObject:@(_yearsData[i])];
    }
    UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc]init];
    dict[@"end"] = @(_yearsEndIndex);
    dict[@"current"] = @(_currentYearsIndex);
    dict[@"index"] = @(_yearsIndex);
    dict[@"max"] = @(UMSTATISTIC_YEARS_MAX);
    dict[@"values"] = a;
    return dict;

}

- (void)setYearsDict:(UMSynchronizedSortedDictionary *)dict
{
    if(dict[@"end"])
    {
        _yearsEndIndex = [dict[@"end"] integerValue];
    }
    if(dict[@"current"])
    {
        _currentYearsIndex = [dict[@"current"] integerValue];
    }
    if(dict[@"index"])
    {
        _yearsIndex = [dict[@"index"] integerValue];
    }
    NSArray *a = NULL;
    id v = dict[@"values"];
    if([v isKindOfClass:[NSArray class]])
    {
        a = (NSArray *)v;
    }
    else if([v isKindOfClass:[UMSynchronizedArray class]])
    {
        UMSynchronizedArray *sa = (UMSynchronizedArray *)v;
        a = [sa arrayCopy];
    }

    if(a)
    {
        NSInteger max = [a count];
        if(max > UMSTATISTIC_YEARS_MAX)
        {
            max = UMSTATISTIC_YEARS_MAX;
        }
        for(NSInteger i=0;i<max;i++)
        {
            _yearsData[i] = [a[i] doubleValue];
        }
    }
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
