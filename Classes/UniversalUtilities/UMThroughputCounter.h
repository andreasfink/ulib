//
//  UMThroughputCounter.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"
#import "UMMicroSec.h"
#import "UMMutex.h"
#include <time.h>
#include <sys/time.h>


@interface UMThroughputCounter : UMObject
{
	long long           _counter;
	UMMicroSec          _duration;
	UMMicroSec          _resolution;
	long long           _cellCount;
	size_t              _cellSize;
	uint32_t            *_cells;
	UMMicroSec          _endTime;	/* time in MicroSeconds */
	long long           _endIndex;   /* time in index counters (MicroSeconds / resolution */
    UMMutex             *_mutex;
}

- (UMThroughputCounter *)init;
- (UMThroughputCounter *)initWithResolutionInMicroseconds:(UMMicroSec)resolution
                                              maxDuration:(UMMicroSec) duration;

- (UMThroughputCounter *)initWithResolutionInMiliseconds:(long long)resolution
                                             maxDuration:(long long)duration;

- (UMThroughputCounter *)initWithResolutionInSeconds:(double)resolution
                                         maxDuration:(double) duration;

+ (UMMicroSec) microsecondTime;


- (void)increase;
- (void)increaseBy:(uint32_t)count;
- (void) timeShiftByIndex:(long long)nowIndex;

- (long long) getCountForMicroseconds:(UMMicroSec)microsecondDuration;
- (long long) getCountForMiliseconds: (long long)milisecondDuration;
- (long long) getCountForSeconds:     (double)secondsDuration;

- (double)	getSpeedForMicroseconds:	(UMMicroSec)microSec;
- (double)	getSpeedForMiliseconds:		(long long)milisec;
- (double)	getSpeedForSeconds:			(double)secondsDuration;
- (void) clear;
- (void) fillWithInt:(uint32_t) i;
- (NSString *) getSpeedString10s;
- (NSString *) getSpeedString5m;
- (NSString *) getSpeedString20m;
- (NSString *) getSpeedStringTriple;
- (NSDictionary *) getSpeedTripleJson;

@end
