//
//  UMStatistic.h
//  ulib
//
//  Created by Andreas Fink on 08.07.19.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"

@class UMStatisticEntry;
@class UMSynchronizedSortedDictionary;
@class UMMutex;

@interface UMStatistic : UMObject
{
    NSString *_path;
    NSString *_name;
    UMSynchronizedSortedDictionary *_entries;
    UMStatisticEntry *_main_entry;
    UMMutex *_lock;
    BOOL _dirty;
}

@property(readwrite,strong,atomic)  NSString *path;
@property(readwrite,strong,atomic)  NSString *name;
@property(readwrite,assign,atomic)  BOOL dirty;


-(UMStatistic *)initWithPath:(NSString *)path name:(NSString *)name;
- (void)flushIfDirty;
- (void)flush;
- (void)setValues:(NSDictionary *)dict;
- (id)getStatisticJsonForKey:(NSString *)key noValues:(BOOL)noValues;
- (void)increaseBy:(double)number;
- (void)increaseBy:(double)number key:(NSString *)key;

@end

