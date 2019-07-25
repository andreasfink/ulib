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
    UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc]init];

    NSArray *keys = [_entries allKeys];
    dict[@"*"] = [_main_entry dictionaryValue];
    for(NSString *key in keys)
    {
        UMStatisticEntry *entry = _entries[key];
        dict[key] = [entry dictionaryValue];
    }
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

- (void)setValues:(NSDictionary *)dict
{
    if(dict[@"name"])
    {
        _name = [dict[@"name"] stringValue];
    }
}

- (void)increaseBy:(double)number
{
    [self increaseBy:number key:NULL];
}

- (void)increaseBy:(double)number key:(NSString *)key
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
            NSArray *keys = [dict allKeys];
            for(NSString *key in keys)
            {
                id obj2 = dict[key];
                if([obj2 isKindOfClass:[NSDictionary class]])
                {
                    NSDictionary *dict2 = (NSDictionary *)obj2;
                    if([key isEqualToString:@"*"])
                    {
                        _main_entry = [[UMStatisticEntry alloc]initWithDictionary:dict2];
                    }
                    else
                    {
                        UMStatisticEntry *entry = [[UMStatisticEntry alloc]initWithDictionary:dict2];
                        _entries[key] = entry;
                    }
                }
            }
        }
    }
}


- (id)getStatisticJsonForKey:(NSString *)key noValues:(BOOL)noValues
{
    /* FIXME */
    return NULL;
}

@end

