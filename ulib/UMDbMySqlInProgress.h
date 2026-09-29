//
//  UMDbMySqlInProgress.h
//  ulibdb
//
//  Created by Andreas Fink on 19.06.14.
//
//

#import <ulib/UMDbSession.h>

@interface UMDbMySqlInProgress : UMDbSession
{
    NSString *query;
    long long start_time;
    long long stop_time;
    UMDbMySqlInProgress *previousQuery;
}

-(id)initWithCString:(const char *)cstr previousQuery:(UMDbMySqlInProgress *)previousQuery;
-(id)initWithString:(NSString *)str previousQuery:(UMDbMySqlInProgress *)previousQuery;
- (long long) completed;
+ (NSArray *)queriesInProgressList;


@property(readwrite,strong)     NSString *query;
@property(readwrite,assign)     long long  start_time;
@property(readwrite,assign)     long long  stop_time;
@property(readwrite,strong)     UMDbMySqlInProgress *previousQuery;

@end
