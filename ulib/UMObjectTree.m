//
//  UMObjectTree.m
//  ulib
//
//  Created by Andreas Fink on 03.11.21.
//  Copyright © 2021 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMObjectTree.h>
#import <ulib/UMObjectTreeEntry.h>

@implementation UMObjectTree

- (UMObjectTree *)init
{
    self = [super init];
    if(self)
    {
        _objectTreeLock = [[UMMutex alloc]initWithName:@"UMObjectTree-mutex"];
        _root = [[UMObjectTreeEntry alloc]init];
    }
    return self;
}

- (void)addEntry:(id)obj  forKeys:(NSArray<NSString *>*)keys
{
    UMObjectTreeEntry *entry = _root;
    NSUInteger max = keys.count;
    for(NSUInteger index=0;index<max;index++)
    {
        NSString *key = keys[index];
        UMObjectTreeEntry *entry2 = [entry getOrCreateEntry:key];
        entry = entry2;
    }
    [entry setPayload:obj];
}

- (id)getEntryForKeys:(NSArray<NSString *>*)keys
{
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
    return payload;
}

- (id)getEntryForKeysReversed:(NSArray<NSString *>*)keys
{
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
    return payload;
}

- (NSArray *)getCumulativeEntryForKeys:(NSArray<NSString *>*)keys
{
    NSMutableArray *results = [[NSMutableArray alloc]init];
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
    return results;
}

- (NSArray *)getCumulativeEntryForKeysReversed:(NSArray<NSString *>*)keys
{
    NSMutableArray *results = [[NSMutableArray alloc]init];
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
    return results;
}


@end

