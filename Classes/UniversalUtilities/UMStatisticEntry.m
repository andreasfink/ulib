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


#define shiftIndex(nowIndex,endIndex,cellCount,cells,cellSize) \
{ \
    if (nowIndex != endIndex) \
    { \
        long long i; \
        long long shiftIndex; \
        shiftIndex = nowIndex - endIndex; \
        if(shiftIndex >= cellCount) \
        { \
            memset((void *)cells,0,cellCount * cellSize ); \
        } \
        else \
        { \
            for(i = endIndex + 1; i <= nowIndex; i++) \
            { \
                cells[i % cellCount] = 0.0; \
            } \
        } \
        endIndex = nowIndex; \
    } \
}

- (void)timeShift
{
    [self updateCurrentTimeIndexes];

    /* shifting seconds */

    shiftIndex(_currentSecondsIndex,_secondsEndIndex,UMSTATISTIC_SECONDS_MAX,_secondsData,sizeof(um_statistic_counter_type));
    shiftIndex(_currentMinutesIndex,_minutesEndIndex,UMSTATISTIC_MINUTES_MAX,_minutesData,sizeof(um_statistic_counter_type));
    shiftIndex(_currentHoursIndex,_hoursEndIndex,UMSTATISTIC_HOURS_MAX,_hoursData,sizeof(um_statistic_counter_type));
    shiftIndex(_currentDaysIndex,_daysEndIndex,UMSTATISTIC_DAYS_MAX,_daysData,sizeof(um_statistic_counter_type));
    shiftIndex(_currentWeeksIndex,_weeksEndIndex,UMSTATISTIC_WEEKS_MAX,_weeksData,sizeof(um_statistic_counter_type));
    shiftIndex(_currentMonthsIndex,_monthsEndIndex,UMSTATISTIC_MONTHS_MAX,_monthsData,sizeof(um_statistic_counter_type));
    shiftIndex(_currentYearsIndex,_yearsEndIndex,UMSTATISTIC_YEARS_MAX,_yearsData,sizeof(um_statistic_counter_type));

}


- (void)increaseBy:(double)count
{
    [_lock lock];
    [self timeShift];
    _secondsData[_currentSecondsIndex % UMSTATISTIC_SECONDS_MAX] += count;
    _minutesData[_currentMinutesIndex % UMSTATISTIC_MINUTES_MAX] += count;
    _hoursData[_currentHoursIndex % UMSTATISTIC_HOURS_MAX] += count;
    _daysData[_currentDaysIndex % UMSTATISTIC_DAYS_MAX] += count;
    _weeksData[_currentWeeksIndex % UMSTATISTIC_WEEKS_MAX] += count;
    _monthsData[_currentMonthsIndex % UMSTATISTIC_MONTHS_MAX] += count;
    _yearsData[_currentYearsIndex % UMSTATISTIC_YEARS_MAX] += count;
    [_lock unlock];
}


- (UMSynchronizedSortedDictionary *)secondsDict
{
    UMSynchronizedArray *a = [[UMSynchronizedArray alloc]init];
    for(NSInteger i=0;i>UMSTATISTIC_SECONDS_MAX;i++)
    {
        [a addObject:@(_secondsData[i])];
    }
    UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc]init];
    dict[@"end"] = @(_secondsEndIndex);
    dict[@"current"] = @(_currentSecondsIndex);
    dict[@"index"] = @(_secondsIndex);
    dict[@"max"] = @(UMSTATISTIC_SECONDS_MAX);
    dict[@"values"] = a;
    return dict;

}

- (void)setSecondsDict:(UMSynchronizedSortedDictionary *)dict
{
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
