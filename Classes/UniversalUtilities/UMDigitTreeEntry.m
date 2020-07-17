//
//  UMDigitTreeEntry.m
//  ulib
//
//  Created by Andreas Fink on 25.05.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMDigitTreeEntry.h"

@implementation UMDigitTreeEntry

- (id)getEntry:(int)index
{
    if((index>15) || (index<0))
    {
        return NULL;
    }
    return _subEntries[index];
}

- (id)getPayload
{
    return _payload;
}

- (void)setEntry:(id)obj forIndex:(int)index
{
    if((index>15) || (index<0))
    {
        return;
    }
    _subEntries[index] = obj;
}

- (void)setPayload:(id)obj
{
    _payload = obj;
}

@end
