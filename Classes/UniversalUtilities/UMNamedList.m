//
//  UMNamedList.m
//  ulib
//
//  Created by Andreas Fink on 19.06.19.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMNamedList.h"
#import "NSString+UMHTTP.h"
#import "UMSynchronizedSortedDictionary.h"

#define DEBUG   1

@implementation UMNamedList


- (UMNamedList *)initWithDirectory:(NSString *)dir name:(NSString *)name
{
    NSString *path = [NSString stringWithFormat:@"%@/%@",dir,name.urlencode];
    return [self initWithPath:path name:name];

}

- (UMNamedList *)initWithPath:(NSString *)path name:(NSString *)name
{
    self = [super init];
    if(self)
    {
        _entries = [[UMSynchronizedSortedDictionary alloc]init];
        _lock  = [[UMMutex alloc]initWithName:@"UMNamedList-lock"];
        _path = path;
        _name = name;
    }
    return self;
}

- (UMNamedList *)init
{
    return [self initWithPath:NULL name:NULL];
}

- (void)addEntry:(NSString *)str
{
    [_lock lock];
    _entries[str] = str;
    _dirty=YES;
    [_lock unlock];
#ifdef DEBUG
    NSLog(@"UMNamedList addEntry:%@",str);
    [self dump];
#endif
}

- (void)removeEntry:(NSString *)str
{
    [_lock lock];
    [_entries removeObjectForKey:str];
    _dirty=YES;
    [_lock unlock];
#ifdef DEBUG
    NSLog(@"UMNamedList removeEntry:%@",str);
    [self dump];
#endif
}

- (BOOL)containsEntry:(NSString *)str
{
    BOOL found = NO;
    [_lock lock];
    NSString *s =  _entries[str];
    if(s!=NULL)
    {
        found = YES;
    }
    [_lock unlock];
    return found;
}


- (NSArray *)allEntries
{
    NSArray *a;
    [_lock lock];
    a = [_entries allKeys];
    [_lock unlock];
    return a;
}

- (void)flush
{
    [_lock lock];
    if(_dirty)
    {
        NSArray *keys = [_entries allKeys];
        NSString *output = [keys componentsJoinedByString:@"\n"];
        NSError *err = NULL;
        [output writeToFile:_path atomically:YES encoding:NSUTF8StringEncoding error:&err];
        if(err)
        {
            NSLog(@"Error while writing namedlist %@ to %@: %@",_name,_path,err);
        }
#ifdef DEBUG
        else
        {
            NSLog(@"Written namedlist '%@ to file '%@'\nContent:\n%@",_name,_path,output);
        }
#endif
        _dirty = NO;
    }
    [_lock unlock];
#ifdef DEBUG
    NSLog(@"UMNamedList flush");
    [self dump];
#endif
}

- (void)reload
{
    [self loadFromFile];
}

- (void)loadFromFile
{
    NSError *err = NULL;
    NSString *s = [NSString stringWithContentsOfFile:_path encoding:NSUTF8StringEncoding error:&err];
    if(err)
    {
        NSLog(@"Error while opening file %@: %@",_path,err);
        return;
    }
    NSArray *lines = [s componentsSeparatedByString:@"\n"];
    UMSynchronizedSortedDictionary *list = [[UMSynchronizedSortedDictionary alloc]init];
    for(NSString *line in lines)
    {
        NSString *value = [line stringByTrimmingCharactersInSet:[UMObject whitespaceAndNewlineCharacterSet]];
        if(value.length > 0) /* we skip empty lines */
        {
            list[value]=value;
        }
    }
    [_lock lock];
    _entries = list;
    _dirty = NO;
    [_lock unlock];
#ifdef DEBUG
    [self dump];
#endif
}

- (void)dump
{
    NSLog(@"[UMNamedList dump] %@",[self description]);
}

- (NSString *)description
{
    UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc]init];
    dict[@"_name"] = _name;
    dict[@"_path"] = _path;
    dict[@"_dirty"] = @(_dirty);
    dict[@"_entries"] = _entries;
    return [dict jsonString];
}

@end
