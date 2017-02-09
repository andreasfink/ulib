//
//  UMAverageDelay.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMAverageDelay.h"

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
        size = s;
        counters = [[NSMutableArray alloc]init];
    }
    return self;
}

- (void) appendNumber:(NSNumber *)nr
{
    @synchronized(self)
    {
        [counters addObject:nr];
        NSInteger i = [counters count];
        while(i > size)
        {
            [counters removeObjectAtIndex:0];
            i--;
        }
    }
}

- (double) averageValue
{
    @synchronized(self)
    {
        double value = 0.0;
        int count = 0;

        for(NSNumber *nr in counters)
        {
            value += [nr doubleValue];
            count++;
        }
        if(count==0)
        {
            return 0.00;
        }
        return (value/count);
    }
}

- (NSString *)description
{
    NSMutableString *s = [[NSMutableString alloc]init];
    double avg = 0.0;
    int count = 0;
    @synchronized(self)
    {
        double sum = 0.0;
        for(NSNumber *nr in counters)
        {
            sum += [nr doubleValue];
            count++;
        }
        if(count==0)
        {
            avg = 0.00;
        }
        else
        {
            avg = (sum/count);
        }
    }
    [s appendFormat:@"UMAverageDelay(count=%d,average=%lf)",count,avg];
    return s;
}
@end
