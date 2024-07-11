//
//  UMAverageDelay.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMAverageDelay.h>

@implementation UMAverageDelay


- (UMAverageDelay *)init
{
    return [self initWithSize:100];
}

- (UMAverageDelay *)initWithSize:(int)s
{
    self = [super init];
    if(self)
    {
        if(s < 10)
        {
            s = 10;
        }
        _size = s;
        _counters = [[NSMutableArray alloc]init];
        _mutex = [[UMMutex alloc]initWithName:@"average-delay-mutex"];
    }
    return self;
}

- (void) appendNumber:(NSNumber *)nr
{
    UMMUTEX_LOCK(_mutex);
    [_counters addObject:nr];
    NSInteger i = [_counters count];
    while(i > _size)
    {
        [_counters removeObjectAtIndex:0];
        i--;
    }
    UMMUTEX_UNLOCK(_mutex);
}

- (double) averageValue
{
    double value = 0.0;
    int count = 0;

    UMMUTEX_LOCK(_mutex);
    for(NSNumber *nr in _counters)
    {
        value += [nr doubleValue];
        count++;
    }
    UMMUTEX_UNLOCK(_mutex);

    if(count==0)
    {
        return 0.00;
    }

    return (value/count);
}

- (NSString *)description
{
    NSMutableString *s = [[NSMutableString alloc]init];
    double avg = 0.0;
    int count = 0;
    double sum = 0.0;
    UMMUTEX_LOCK(_mutex);
    for(NSNumber *nr in _counters)
    {
        sum += [nr doubleValue];
        count++;
    }
    UMMUTEX_UNLOCK(_mutex);

    if(count==0)
    {
        avg = 0.00;
    }
    else
    {
        avg = (sum/count);
    }
    [s appendFormat:@"UMAverageDelay(count=%d,average=%lf)",count,avg];
    return s;
}
@end
