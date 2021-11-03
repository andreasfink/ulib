//
//  UMObjectTreeEntry.m
//  ulib
//
//  Created by Andreas Fink on 03.11.21.
//  Copyright © 2021 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObjectTreeEntry.h"

@implementation UMObjectTreeEntry

- (UMObjectTreeEntry *)init
{
    self = [super init];
    if(self)
    {
        _subEntries = [[UMSynchronizedDictionary alloc]init];
    }
    return self;
}

- (id)getEntry:(NSString *)key
{
    return _subEntries[key];
}

- (id)getPayload
{
    return _payload;
}

- (void)setEntry:(id)obj forKey:(NSString *)key
{
    _subEntries[key] = obj;
}

- (void)setPayload:(id)obj
{
    _payload = obj;
}

@end
