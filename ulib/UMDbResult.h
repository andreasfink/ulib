//
//  UMDbResult.h
//  ulibdb.framework
//
//  Created by Andreas Fink on 24.10.11.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.

#import <ulib/UMObject.h>

@interface UMDbResult : UMObject
{
    long            _indexPointer;
    long long       _affectedRows;    
    NSMutableArray *_resultArray;
    NSMutableArray *_columNames;
    NSMutableArray *_columTypes;
    NSMutableArray *_columCharsets;
}

@property (readwrite,assign) long long affectedRows;
@property (readwrite,strong) NSMutableArray *columNames;
@property (readwrite,strong) NSMutableArray *columTypes;
@property (readwrite,strong) NSMutableArray *columCharsets;
@property (readwrite,strong) NSMutableArray *resultArray;

- (id)initForFile:(const char *)file line:(long)line;
- (void)addRow:(NSArray *)arr;
- (void)setRow:(NSArray *)arr forIndex:(long)idx;
- (void)setColumName:(NSString *)name forIndex:(long)idx;
- (void)setColumType:(NSNumber *)type forIndex:(long)idx;
- (void)setColumCharset:(NSNumber *)type forIndex:(long)idx;
- (NSNumber *)columTypeForIndex:(long)idx;
- (NSNumber *)columCharsetForIndex:(long)idx;
- (id)getRow:(long)idx;
- (id)fetchRow;
- (NSDictionary *)fetchRowAsDictionary;
- (void) reset;
- (NSUInteger)rowsCount;
- (NSUInteger)columsCount;
@end
