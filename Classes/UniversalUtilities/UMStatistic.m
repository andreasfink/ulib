//
//  UMStatistic.m
//  ulib
//
//  Created by Andreas Fink on 08.07.19.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMStatistic.h"
#import "UMSynchronizedDictionary.h"
#import "UMSynchronizedSortedDictionary.h"
#import "UMStatisticEntry.h"
#import "UMMutex.h"
#import "NSString+UMHTTP.h"
#import "UMJsonParser.h"

@implementation UMStatistic

-(UMStatistic *)initWithPath:(NSString *)path name:(NSString *)name
{
    self = [super init];
    if(self)
    {
        _name = name;
        _path = path;
        _dirty = YES;
        _entries = [[UMSynchronizedSortedDictionary alloc]init];
        _main_entry = [[UMStatisticEntry alloc]init];
        _lock = [[UMMutex alloc]init];
    }
    return self;
}

- (void)flushIfDirty
{
    [_lock lock];

    if(_dirty)
    {
        [self flush];
    }
    [_lock unlock];
}


- (void)flush
{
    [_lock lock];

    UMSynchronizedSortedDictionary *dict = [self objectValue:YES];
    NSString *jsonString = [dict jsonString];

    NSString *filePath = [NSString stringWithFormat:@"%@/%@",_path,_name.urlencode];
    NSError *err = NULL;
    [jsonString writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&err];
    if(err)
    {
        NSLog(@"Error while writing statistics %@ to %@: %@",_name,_path,err);
    }
    _dirty = NO;
    [_lock unlock];
}

- (UMSynchronizedSortedDictionary *)objectValue:(BOOL)includeSubs
{
    UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc]init];
    dict[@"name"] = _name;
    dict[@"statistic"] = [_main_entry dictionaryValue];

    if(includeSubs)
    {
        UMSynchronizedSortedDictionary *dict2 = [[UMSynchronizedSortedDictionary alloc]init];
        NSArray *keys = [_entries allKeys];
        for(NSString *key in keys)
        {
            UMStatisticEntry *entry = _entries[key];
            dict2[key] = [entry dictionaryValue];
        }
        
        dict[@"statistic-by-key"] = dict2;
    }
    return dict;
}

- (void)setValues:(NSDictionary *)dict
{
    if(dict[@"name"])
    {
        _name = [dict[@"name"] stringValue];
    }
    if(dict[@"statistic"])
    {
        id stat = dict[@"statistic"];
        if([stat isKindOfClass:[NSDictionary class]])
        {
            _main_entry = [[UMStatisticEntry alloc]initWithDictionary:(NSDictionary *)stat];
        }
    }
    if(dict[@"statistic-by-key"])
    {
        _entries = [[UMSynchronizedSortedDictionary alloc]init];
        id stat = dict[@"statistic-by-key"];
        if([stat isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *dict = (NSDictionary *)stat;
            NSArray *allkeys = [dict allKeys];
            for(NSString *key in allkeys)
            {
                UMStatisticEntry *e = [[UMStatisticEntry alloc]initWithDictionary:dict[key]];
                _entries[key]=e;
            }
        }
    }
}

- (void)increaseBy:(double)number
{
    [self increaseBy:number forKey:NULL];
}

- (void)increaseBy:(double)number forKey:(NSString *)key
{
    [_main_entry increaseBy:number];
    if(key.length > 0)
    {
        UMStatisticEntry *e = _entries[key];
        if(e==0)
        {
            e = [[UMStatisticEntry alloc]init];
            e.name = key;
            _entries[key] = e;
        }
        [e increaseBy:number];
    }
}

- (void)loadFromFile
{
    _main_entry = [[UMStatisticEntry alloc]init];
    _entries = [[UMSynchronizedSortedDictionary alloc]init];

    NSString *filePath = [NSString stringWithFormat:@"%@/%@",_path,_name.urlencode];
    NSError *err = NULL;
#ifdef __APPLE__
    NSData *jsonData = [[NSData alloc]initWithContentsOfFile:filePath options:0 error:&err];
#else
    NSData *jsonData = [[NSData alloc]initWithContentsOfFile:filePath];
#endif
    if(err)
    {
        NSLog(@"Error while reading statistics %@ to %@: %@",_name,_path,err);
    }
    else
    {
        UMJsonParser *parser = [[UMJsonParser alloc]init];
        id obj = [parser objectWithData:jsonData];
        if([obj isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *dict = (NSDictionary *)obj;
            [self setValues:dict];
        }
    }
}


- (UMSynchronizedSortedDictionary *)getStatistic
{
    UMSynchronizedSortedDictionary *dict = [self objectValue:NO];
    return dict;
}

- (UMSynchronizedSortedDictionary *)getStatistics
{
    UMSynchronizedSortedDictionary *dict = [self objectValue:YES];
    return dict;
}



- (UMSynchronizedSortedDictionary *)getStatisticForKey:(NSString *)key
{
    UMStatisticEntry *entry;
    entry = _entries[key];
    
    UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc]init];
    dict[@"name"] = _name;

    UMSynchronizedSortedDictionary *dict2 = [[UMSynchronizedSortedDictionary alloc]init];
    if(entry)
    {
        dict2[key] = [entry dictionaryValue];
    }
    dict[@"statistic-by-key"] = dict2;
    return dict;
}

@end

