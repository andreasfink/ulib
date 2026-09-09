//
//  UMDbMySqlInProgress.m
//  ulibdb
//
//  Created by Andreas Fink on 19.06.14.
//
//

#import "UMDbMySqlInProgress.h"


NSMutableArray *queriesInProgress;

@implementation UMDbMySqlInProgress
@synthesize query;
@synthesize start_time;
@synthesize stop_time;
@synthesize previousQuery;

-(id)initWithCString:(const char *)cstr previousQuery:(UMDbMySqlInProgress *)pq
{
    self = [super init];
    if(self)
    {
        self.query = [NSString stringWithUTF8String:cstr];
        self.start_time = [UMUtil milisecondClock];
        if(queriesInProgress==NULL)
        {
            queriesInProgress = [[NSMutableArray alloc]init];
        }
        self.previousQuery = pq;
        pq.previousQuery = NULL;
        @synchronized(queriesInProgress)
        {
            [queriesInProgress addObject:self];
        }
    }
    return self;
}


-(id)initWithString:(NSString *)str previousQuery:(UMDbMySqlInProgress *)pq
{
    self = [super init];
    if(self)
    {
        self.query = str;
        self.start_time = [UMUtil milisecondClock];
        if(queriesInProgress==NULL)
        {
            queriesInProgress = [[NSMutableArray alloc]init];
        }
        self.previousQuery = pq;
        pq.previousQuery = NULL;
        @synchronized(queriesInProgress)
        {
            [queriesInProgress addObject:self];
        }
    }
    return self;
}


- (long long) completed
{
    self.stop_time = [UMUtil milisecondClock];
    @synchronized(queriesInProgress)
    {
        [queriesInProgress removeObject:self];
    }
    previousQuery = NULL; /* we are now the last query */
    return (stop_time - start_time);

}

+ (NSArray *)queriesInProgressList
{
    NSMutableArray *s = [[NSMutableArray alloc]init];
    @synchronized(queriesInProgress)
    {
        for(UMDbMySqlInProgress *query in queriesInProgress)
        {
            [s addObject:query];
        }
    }
    return s;
}

@end
