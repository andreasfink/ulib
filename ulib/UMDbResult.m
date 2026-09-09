//
//  UMDbResult.m
//  ulibdb.framework
//
//  Created by Andreas Fink on 24.10.11.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.

#import <ulib/ulib.h>
#import "ulibdb_defines.h"
#import "UMDbResult.h"
#import <ulib/ulib_config.h>

@implementation UMDbResult


- (id)initForFile:(const char *)file line:(long)line
{
    @autoreleasepool
    {
//        NSString *fileName = @(file);
//        fileName = [fileName lastPathComponent];
#pragma unused(file)
        self = [super init];
        if(self)
        {
            _resultArray = [[NSMutableArray alloc]init];
            _columNames  = [[NSMutableArray alloc]init];
            _columTypes  = [[NSMutableArray alloc]init];
            _columCharsets  = [[NSMutableArray alloc]init];
        }
        return self;
    }
}

- (id)init
{
    self = [super init];
    if(self)
    {
        _resultArray = [[NSMutableArray alloc]init];
        _columNames  = [[NSMutableArray alloc]init];
        _columTypes  = [[NSMutableArray alloc]init];
        _columCharsets  = [[NSMutableArray alloc]init];
    }
    return self;
}

- (NSString*) description
{
	NSMutableString *s;
	s = [[NSMutableString alloc] initWithFormat:@"UMDbResult: index pointer: %ld\n",
         _indexPointer];
    [s appendFormat:@"affectedRows: %lld\n", _affectedRows];
    [s appendFormat:@"result array: %@\n", _resultArray];
    [s appendFormat:@"column names: %@\n", _columNames];
    [s appendFormat:@"column types: %@\n", _columTypes];
    [s appendFormat:@"column charsets: %@\n", _columCharsets];
	return s;
}

- (void)addRow:(NSArray *)arr
{
    [_resultArray addObject:arr];
}

- (void)addRow:(id)o columName:(NSString *)name
{
    [_resultArray addObject:o];
    [_columNames addObject:name];

}

- (void)setRow:(NSArray *)arr forIndex:(long)idx
{
    @autoreleasepool
    {
        if(idx == [_resultArray count])
        {
            [_resultArray addObject:arr];
        }
        else if(idx < [_resultArray count])
        {
            _resultArray[idx] = arr;
        }
        else
        {
            while([_resultArray count] < (idx-1))
            {
                [_resultArray addObject:[NSNull null]];
            }
            [_resultArray addObject:arr];
        }
    }
}

- (void)setColumName:(NSString *)n forIndex:(long)idx
{
    @autoreleasepool
    {
        if(idx == [_columNames count])
        {
            [_columNames addObject:n];
        }
        else if(idx < [_columNames count])
        {
            _columNames[idx] = n;
        }
        else
        {
            while([_columNames count] < (idx-1))
            {
                [_columNames addObject:[NSNull null]];
            }
            [_columNames addObject:n];
        }
    }
}

- (void)setColumType:(NSNumber *)type forIndex:(long)idx
{    
    @autoreleasepool
    {
        if(idx == [_columTypes count])
        {
            [_columTypes addObject:type];
        }
        else if(idx < [_columTypes count])
        {
            _columTypes[idx] = type;
        }
        else
        {
            while([_columTypes count] < (idx-1))
            {
                [_columTypes addObject:[NSNull null]];
            }
            [_columTypes addObject:type];
        }
    }
}

- (void)setColumCharset:(NSNumber *)type forIndex:(long)idx
{
    @autoreleasepool
    {
        if(idx == [_columCharsets count])
        {
            [_columCharsets addObject:type];
        }
        else if(idx < [_columCharsets count])
        {
            _columCharsets[idx] = type;
        }
        else
        {
            while([_columCharsets count] < (idx-1))
            {
                [_columCharsets addObject:[NSNull null]];
            }
            [_columCharsets addObject:type];
        }
    }
}

- (NSNumber *)columTypeForIndex:(long)idx
{
    if(_columTypes.count > idx)
    {
        return _columTypes[idx];
    }
    return NULL;
}


- (NSNumber *)columCharsetForIndex:(long)idx
{
    if(_columCharsets.count > idx)
    {
        return _columCharsets[idx];
    }
    return NULL;
}

- (NSUInteger)rowsCount
{
    return [_resultArray count];
}

- (NSUInteger)columsCount
{
    return [_columNames count];
}

- (NSArray *)getRow:(long)idx
{
    if(idx >= [_resultArray count])
    {
        return NULL;
    }
    return (NSArray *)_resultArray[idx];
}

- (NSArray *)fetchRow
{
    return [self getRow:_indexPointer++];
}

- (NSDictionary *)fetchRowAsDictionary
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    NSArray *row = [self fetchRow];
    for(NSInteger i=0;i<row.count;i++)
    {
        id value = row[i];
        id name = _columNames[i];
        if(value == NULL)
        {
            value = [NSNull null];
        }
        if(name==NULL)
        {
            name = @(i);
        }
        dict[name] = value;
    }
    return dict;
}

- (void)reset
{
    _indexPointer = 0;
}

@end
