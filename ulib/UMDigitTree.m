//
//  UMDigitTree.m
//  ulib
//
//  Created by Andreas Fink on 25.05.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMDigitTree.h>

@implementation UMDigitTree

- (UMDigitTree *)init
{
    self = [super init];
    if(self)
    {
        _digitTreeLock = [[UMMutex alloc]initWithName:@"UMDigitTree-mutex"];
    }
    return self;
}

- (void)addEntry:(id)obj  forDigits:(NSString *)digits
{
    [_digitTreeLock lock];
    if(_root==NULL)
    {
        _root = [[UMDigitTreeEntry alloc]init];
    }
    UMDigitTreeEntry *entry = _root;
    NSUInteger length = digits.length;
    for(NSUInteger index=0;index<length;index++)
    {
        unichar uc = [digits characterAtIndex:index];
        int i = [UMDigitTree indexFromUnichar:uc];
        if(i<0)
        {
            continue;
        }
        UMDigitTreeEntry *entry2 = [entry getEntry:i];
        if(entry2 == NULL)
        {
            entry2 = [[UMDigitTreeEntry alloc]init];
            [entry setEntry:entry2 forIndex:i];
        }
        entry = entry2;
    }
    [entry setPayload:obj];
    [_digitTreeLock unlock];
}

- (id)getEntryForDigits:(NSString *)digits
{
    [_digitTreeLock lock];
    UMDigitTreeEntry *entry = _root;
    id payload = [entry getPayload];
    
    NSUInteger length = digits.length;
    for(NSUInteger index=0;index<length;index++)
    {
        unichar uc = [digits characterAtIndex:index];
        int i = [UMDigitTree indexFromUnichar:uc];
        if(i<0)
        {
            continue;
        }
        UMDigitTreeEntry *entry2 = [entry getEntry:i];
        if(entry2 == NULL)
        {
            break;
        }
        entry = entry2;
        payload = [entry getPayload];
    }
    [_digitTreeLock unlock];
    return payload;
}

+(int)indexFromUnichar:(unichar)uc
{
    switch(uc)
    {
        case '0':
            return 0;
        case '1':
            return 1;
        case '2':
            return 2;
        case '3':
            return 3;
        case '4':
            return 4;
        case '5':
            return 5;
        case '6':
            return 6;
        case '7':
            return 7;
        case '8':
            return 8;
        case '9':
            return 9;
        case 'a':
        case 'A':
            return 10;
        case 'b':
        case 'B':
            return 11;
        case 'c':
        case 'C':
            return 12;
        case 'd':
        case 'D':
            return 13;
        case 'e':
        case 'E':
            return 14;
        case 'f':
        case 'F':
            return 15;
    }
    return -1;
}

@end
