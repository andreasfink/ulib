//
//  UMThroughputCounter.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMThroughputCounter.h"

#include <math.h>
//double log2f(double x);
#define	tc_cell(tc,second)			tc->cnt[second % MAX_THROUGHPUT_COUNTER]

@implementation UMThroughputCounter


- (UMThroughputCounter *)init
{
	return [self initWithResolutionInSeconds: 0.25 maxDuration: 1260.0];
}

- (UMThroughputCounter *)initWithResolutionInMiliseconds:(long long)res
                                             maxDuration:(UMMicroSec) dur;
{
	return [self initWithResolutionInMicroseconds:(res*1000ULL)
                                      maxDuration:(dur*1000ULL)];
}

- (UMThroughputCounter *)initWithResolutionInMicroseconds:(UMMicroSec)res
                                              maxDuration:(UMMicroSec)dur;
{
    self = [super init];
    if(self)
    {
        NSAssert(res > 0,   @"UMThroughputCounter: resolution must be larger than zero");
        NSAssert(dur   > 0, @"UMThroughputCounter: duration must be larger than zero");
        _resolution = res;
        _duration = dur;

        if(_duration < (_resolution*16))
        {
            _duration = _resolution * 16;
        }
        _cellCount = 1<<((int)log2f((double)_duration / (double)_resolution) + 1); /* round up to the next power of */

        _cellSize = (size_t)_cellCount * (size_t)sizeof(uint32_t);
        if(_cellSize > 32768)
        {
            NSLog(@"Warning: ThroughputCounter size is %ld kbytes! Probably very ineficcient",(long)_cellSize/1024);
        }
        _cells = (uint32_t *)malloc(_cellSize+4);
        NSAssert(_cells,([NSString stringWithFormat:@"Could not allocate %ld kbytes for Throughput counter", (long)_cellSize/1024]));
        memset(_cells,0x00,_cellSize+4);
        _endTime   = [UMThroughputCounter microsecondTime];
        _endIndex  = _endTime/_resolution;
    }
	return self;
}

- (UMThroughputCounter *)initWithResolutionInSeconds:(double)res
                                         maxDuration:(double)dur
{
	return [self initWithResolutionInMicroseconds:(UMMicroSec)(res * 1000000.0f)
                                      maxDuration:(UMMicroSec)(dur * 1000000.0)];
}

- (void)dealloc
{
    free(_cells);
    _cells = NULL;
}

+ (UMMicroSec) microsecondTime
{
	struct	timeval  tp;
	struct	timezone tzp;
    gettimeofday(&tp, &tzp);
	return (UMMicroSec)tp.tv_sec * 1000000LL + ((UMMicroSec)tp.tv_usec);
}


- (void)increase
{
	[self increaseBy: 1];
}



- (void)increaseBy:(uint32_t)count
{
    UMMicroSec nowTime = [UMThroughputCounter microsecondTime];

    [_mutex lock];
    long long nowIndex = nowTime/_resolution;
    [self timeShiftByIndex: nowIndex];
    _cells[nowIndex % _cellCount] += count;
    [_mutex unlock];
}


- (void) timeShiftByIndex:(long long)nowIndex
{
	long long i;
	long long shiftIndex;

	if (nowIndex == _endIndex)
    {
		return;
    }
    shiftIndex = nowIndex - _endIndex;
	if(shiftIndex >= _cellCount)
	{
		memset((void *)_cells,0,_cellSize);
		goto end;
	}
	for(i = _endIndex + 1; i <= nowIndex; i++)
    {
		_cells[i % _cellCount] = 0;
    }
end:
	_endIndex = nowIndex;
}

- (long long) getCountForSeconds: (double)secondsDuration
{
	return [self getCountForMicroseconds:(long long)(secondsDuration * 1000000.0f)];
}

- (long long) getCountForMiliseconds: (long long)milisecondDuration
{
	return [self getCountForMicroseconds: (milisecondDuration * 1000LL)];
}

- (long long) getCountForMicroseconds: (UMMicroSec)microsecondDuration;
{
    long long startIndex;
    UMMicroSec nowTime;
    long long nowIndex;
    long long indexCount;
    long long result;
    long long i;

    nowTime  = [UMThroughputCounter microsecondTime];

    [_mutex lock];
    nowIndex = nowTime/_resolution;
    [self timeShiftByIndex: nowIndex];
    indexCount = microsecondDuration/_resolution;
    if(indexCount >= _cellCount)
    {
        indexCount = _cellCount-1;
    }
    startIndex = nowIndex - 1 - indexCount;

    result = 0;
    for ( i = startIndex; i < (nowIndex -1); i++ )
    {
        result += _cells[i % _cellCount];
    }
    [_mutex unlock];

    return result;
}


- (double) getSpeedForMiliseconds: (long long)dur
{
	return [self getSpeedForMicroseconds: (dur * 1000LL)];
}


- (double) getSpeedForSeconds: (double)dur
{
	return [self getSpeedForMicroseconds: (long long)(dur * 1000000.0f)];
}


- (double) getSpeedForMicroseconds: (UMMicroSec)microsecondDuration
{
	long long count;
	
	count = [self getCountForMicroseconds:microsecondDuration];
	return (double)count / ((double) microsecondDuration / 1000000.0f);
}
	

- (NSString *) getSpeedString10s
{
	return [NSString stringWithFormat:@"%8.3f/s\n", (double)[self getSpeedForMicroseconds: 10000000LL]];
}


- (NSString *) getSpeedString5m
{
	return [NSString stringWithFormat:@"%8.3f/s\n", (double)[self getSpeedForMicroseconds: 300000000LL]];
}


- (NSString *) getSpeedString20m
{
	return [NSString stringWithFormat:@"%8.3f/s\n", (double)[self getSpeedForMicroseconds: 1200000000LL]];
}


- (NSString *) getSpeedStringTriple
{
    return [NSString stringWithFormat:@"10s: %8.3f/s  5m: %8.3f/s  20m: %8.3f/s\n",
			(double)[self getSpeedForMicroseconds:   10000000ULL],
			(double)[self getSpeedForMicroseconds:  300000000ULL],
			(double)[self getSpeedForMicroseconds: 1200000000ULL]];
}

- (NSDictionary *) getSpeedTripleJson
{
    NSMutableDictionary *d = [[NSMutableDictionary alloc]init];
    d[@"10s"] = @([self getSpeedForMicroseconds:   10000000ULL]);
    d[@"30s"] = @([self getSpeedForMicroseconds:   300000000ULL]);
    d[@"120s"] = @([self getSpeedForMicroseconds:   1200000000ULL]);
    return d;
}

- (NSString *)description
{
    return [self getSpeedStringTriple];
}

- (void)clear
{
	[self fillWithInt: 0];
}

- (void)fillWithInt:(uint32_t)j
{
	int i;
	for(i=0;i<_cellCount;i++)
    {
		_cells[i%_cellCount]=j;
    }
}

@end

