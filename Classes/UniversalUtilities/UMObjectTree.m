//
//  UMObjectTree.m
//  ulib
//
//  Created by Andreas Fink on 03.11.21.
//  Copyright © 2021 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObjectTree.h"
#import "UMObjectTreeEntry.h"

@implementation UMObjectTree

- (UMObjectTree *)init
{
    self = [super init];
    if(self)
    {
        _lock = [[UMMutex alloc]initWithName:@"UMObjectTree-mutex"];
    }
    return self;
}

- (void)addEntry:(id)obj  forKeys:(NSArray<NSString *>*)keys
{
    [_lock lock];
    if(_root==NULL)
    {
        _root = [[UMObjectTreeEntry alloc]init];
    }
    UMObjectTreeEntry *entry = _root;
    NSUInteger max = keys.count;
    for(NSUInteger index=0;index<max;index++)
    {
        NSString *key = keys[index];
        UMObjectTreeEntry *entry2 = [entry getEntry:key];
        if(entry2 == NULL)
        {
            entry2 = [[UMObjectTreeEntry alloc]init];
            [entry setEntry:entry2 forKey:key];
        }
        entry = entry2;
    }
    [entry setPayload:obj];
    [_lock unlock];
}

- (id)getEntryForKeys:(NSArray<NSString *>*)keys
{
    [_lock lock];
    UMObjectTreeEntry *entry = _root;
    id payload = [entry getPayload];
    
    NSUInteger length = keys.count;
    for(NSUInteger index=0;index<length;index++)
    {
        NSString *key = keys[index];
        UMObjectTreeEntry *entry2 = [entry getEntry:key];
        if(entry2 == NULL)
        {
            break;
        }
        entry = entry2;
        payload = [entry getPayload];
    }
    [_lock unlock];
    return payload;
}

- (id)getEntryForKeysReversed:(NSArray<NSString *>*)keys
{
    [_lock lock];
    UMObjectTreeEntry *entry = _root;
    id payload = [entry getPayload];
    
    NSUInteger length = keys.count;
    for(NSUInteger index=length-1;index>=0;index--)
    {
        NSString *key = keys[index];
        UMObjectTreeEntry *entry2 = [entry getEntry:key];
        if(entry2 == NULL)
        {
            break;
        }
        entry = entry2;
        payload = [entry getPayload];
    }
    [_lock unlock];
    return payload;
}

- (NSArray *)getCumulativeEntryForKeys:(NSArray<NSString *>*)keys
{
    NSMutableArray *results = [[NSMutableArray alloc]init];
    [_lock lock];
    UMObjectTreeEntry *entry = _root;
    id payload = [entry getPayload];
    if(payload)
    {
        [results addObject:payload];
    }
    NSUInteger length = keys.count;
    for(NSUInteger index=0;index<length;index++)
    {
        NSString *key = keys[index];
        UMObjectTreeEntry *entry2 = [entry getEntry:key];
        if(entry2 == NULL)
        {
            break;
        }
        entry = entry2;
        payload = [entry getPayload];
        if(payload)
        {
            [results addObject:payload];
        }
    }
    [_lock unlock];
    return results;
}

- (NSArray *)getCumulativeEntryForKeysReversed:(NSArray<NSString *>*)keys
{
    NSMutableArray *results = [[NSMutableArray alloc]init];
    [_lock lock];
    UMObjectTreeEntry *entry = _root;
    id payload = [entry getPayload];
    if(payload)
    {
        [results addObject:payload];
    }
    NSUInteger length = keys.count;
    for(NSUInteger index=length-1;index>=0;index--)
    {
        NSString *key = keys[index];
        UMObjectTreeEntry *entry2 = [entry getEntry:key];
        if(entry2 == NULL)
        {
            break;
        }
        entry = entry2;
        payload = [entry getPayload];
        if(payload)
        {
            [results addObject:payload];
        }
    }
    [_lock unlock];
    return results;
}


@end

