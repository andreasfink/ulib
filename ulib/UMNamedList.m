//
//  UMNamedListOld.m
//  ulib
//
//  Created by Andreas Fink on 19.06.19.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMNamedList.h>
#import <ulib/NSString+ulib.h>
#import <ulib/UMSynchronizedSortedDictionary.h>
#import <ulib/UMAssert.h>

//#define DEBUG   1

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
        _namedlistEntries = [[UMSynchronizedSortedDictionary alloc]init];
        _namedListLock  = [[UMMutex alloc]initWithName:@"UMNamedList-lock"];
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
    UMAssert(_namedlistEntries!=NULL,@"_entries can not be NULL");
    UMAssert(_namedListLock!=NULL,@"_lock should not be NULL");
    if(![_namedlistEntries isKindOfClass:[UMSynchronizedSortedDictionary class]])
    {

<<<<<<< HEAD
        NSLog(@"_namedlistEntries is not UMSynchronizedSortedDictionary but %@ class", _namedlistEntries.description);
=======
        NSLog(@"_namedlistEntries is not UMSynchronizedSortedDictionary but %@ class", _namedlistEntries.className);
>>>>>>> origin/release-2.1
        return;
    }
    if(![str isKindOfClass:[NSString class]])
    {
        NSLog(@"you can not add anything else than a string");
        return;
    }
    if(str.length == 0)
    {
        NSLog(@"you can not add empty string");
        return;
    }
    UMAssert(_namedListLock!=NULL,@"_lock is NULL");
    
        ummutex_lock(_namedListLock);
    _namedlistEntries[str] = str;
    _dirty=YES;
        ummutex_unlock(_namedListLock);
#ifdef DEBUG
    NSLog(@"UMNamedList addEntry:%@",str);
    [self dump];
#endif
}

- (void)removeEntry:(NSString *)str
{
    UMAssert(_namedlistEntries!=NULL,@"_entries can not be NULL");
    UMAssert(_namedListLock!=NULL,@"_lock should not be NULL");
    if(![_namedlistEntries isKindOfClass:[UMSynchronizedSortedDictionary class]])
    {
<<<<<<< HEAD
        NSLog(@"_namedlistEntries is not UMSynchronizedSortedDictionary but %@", [_namedlistEntries description]);
=======
        NSLog(@"_namedlistEntries is not UMSynchronizedSortedDictionary but %@ class", _namedlistEntries.className);
>>>>>>> origin/release-2.1
        return;
    }

    if(![str isKindOfClass:[NSString class]])
    {
        NSLog(@"you can not remove anything else than a string");
        return;
    }
    if(str.length == 0)
    {
        NSLog(@"you can not remove empty string");
        return;
    }
        ummutex_lock(_namedListLock);
    [_namedlistEntries removeObjectForKey:str];
    _dirty=YES;
        ummutex_unlock(_namedListLock);
#ifdef DEBUG
    NSLog(@"UMNamedList removeEntry:%@",str);
    [self dump];
#endif
}

- (BOOL)containsEntry:(NSString *)str
{
    BOOL found = NO;
        ummutex_lock(_namedListLock);
    NSString *s =  _namedlistEntries[str];
    if(s!=NULL)
    {
        found = YES;
    }
        ummutex_unlock(_namedListLock);
    return found;
}


- (NSArray *)allEntries
{
    NSArray *a;
        ummutex_lock(_namedListLock);
    a = [_namedlistEntries allKeys];
        ummutex_unlock(_namedListLock);
    return a;
}

- (void)flush
{
        ummutex_lock(_namedListLock);
    if(_dirty)
    {
        NSArray *keys = [_namedlistEntries allKeys];
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
        ummutex_unlock(_namedListLock);
#ifdef DEBUG
//    NSLog(@"UMNamedList flush");
//    [self dump];
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
    ummutex_lock(_namedListLock);
    _namedlistEntries = list;
    _dirty = NO;
    ummutex_unlock(_namedListLock);
#ifdef DEBUG
    [self dump];
#endif
}

- (void)dump
{
    NSLog(@"UMNamedList dump:");
    NSLog(@"_name: %@",_name);
    NSLog(@"_path: %@",_path);
    NSLog(@"_dirty: %@",@(_dirty));
    NSLog(@"_name: %@",_name);
    NSLog(@"_namedlistEntries: %@",_namedlistEntries);

//    NSLog(@"[UMNamedList %p dump] %@",self,[self description]);
}

- (NSString *)description
{
    UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc]init];
    dict[@"_name"] = (_name ? _name : @"(null)");
    dict[@"_path"] = (_path ? _path : @"(null)");
    dict[@"_dirty"] = (_dirty ? @"YES" : @"NO");
    if(![_namedlistEntries isKindOfClass:[UMSynchronizedSortedDictionary class]])
    {
        NSObject *o = _namedlistEntries;
<<<<<<< HEAD
        NSString *s = o.description;
=======
        NSString *s = o.className;
>>>>>>> origin/release-2.1
        NSLog(@"_namedlistEntries is not UMSynchronizedSortedDictionary but %@ class",s);
    }
    else
    {
        dict[@"_namedlistEntries"] = (_namedlistEntries ? _namedlistEntries : @"(null)");
    }
    return [dict jsonString];
}

- (UMNamedList *)copyWithZone:(NSZone *)zone
{
    UMNamedList *n = [[UMNamedList allocWithZone:zone]init];
    n->_name = _name;
    n->_path = _path;
    n->_dirty = _dirty;
    n->_namedlistEntries = [_namedlistEntries copyWithZone:zone];
    return n;
}

@end
