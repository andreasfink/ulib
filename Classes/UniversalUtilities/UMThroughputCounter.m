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
    self=[super init];
    if(self)
    {
        NSAssert(res > 0,   @"UMThroughputCounter: resolution must be larger than zero");
        NSAssert(dur   > 0, @"UMThroughputCounter: duration must be larger than zero");
        resolution = res;
        duration = dur;

        if(duration < (resolution*16))
        {
            duration = resolution * 16;
        }
        cellCount = 1<<((int)log2f((double)duration / (double)resolution) + 1); /* round up to the next power of */

        cellSize = (size_t)cellCount * (size_t)sizeof(uint32_t);
        if(cellSize > 32768)
        {
            NSLog(@"Warning: ThroughputCounter size is %ld kbytes! Probably very ineficcient",(long)cellSize/1024);
        }
        cells = (uint32_t *)malloc(cellSize);
        NSAssert(cells,([NSString stringWithFormat:@"Could not allocate %ld kbytes for Throughput counter", (long)cellSize/1024]));
        memset(cells,0x00,cellSize);
        endTime   = [UMThroughputCounter microsecondTime];
        endIndex  = endTime/resolution;
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
    free(cells);
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
    long long nowIndex = nowTime/resolution;
    [self timeShiftByIndex: nowIndex];
    cells[nowIndex % cellCount] += count;
    [_mutex unlock];
}


- (void) timeShiftByIndex:(long long)nowIndex
{
	long long i;
	long long shiftIndex;

	if (nowIndex == endIndex)
    {
		return;
    }
    shiftIndex = nowIndex - endIndex;
	if(shiftIndex >= cellCount)
	{
		memset((void *)cells,0,cellSize);
		goto end;
	}
	for(i = endIndex + 1; i <= nowIndex; i++)
    {
		cells[i % cellCount] = 0;
    }
end:
	endIndex = nowIndex;
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
    nowIndex = nowTime/resolution;
    [self timeShiftByIndex: nowIndex];
    indexCount = microsecondDuration/resolution;
    if(indexCount >= cellCount)
    {
        indexCount = cellCount-1;
    }
    startIndex = nowIndex - 1 - indexCount;

    result = 0;
    for ( i = startIndex; i < (nowIndex -1); i++ )
    {
        result += cells[i % cellCount];
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
	for(i=0;i<cellCount;i++)
    {
		cells[i%cellCount]=j;
    }
}

@end

