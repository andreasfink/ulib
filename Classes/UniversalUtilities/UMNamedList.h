//
//  UMNamedList.h
//  ulib
//
//  Created by Andreas Fink on 19.06.19.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"


@interface UMNamedList : UMObject
{
    NSString        *_name;
    NSString        *_path;
    BOOL            _dirty;
    NSMutableDictionary *_entries;
    UMMutex         *_lock;
}


@property(readwrite,strong,atomic)  NSString *name;
@property(readwrite,strong,atomic)  NSString *path;
@property(readwrite,assign,atomic)  BOOL dirty;
@property(readwrite,strong,atomic)  NSMutableDictionary *entries;
@property(readwrite,strong,atomic)  UMMutex     *lock;


- (UMNamedList *)initWithDirectory:(NSString *)dir name:(NSString *)name;
- (UMNamedList *)initWithPath:(NSString *)path name:(NSString *)name;
- (void)addEntry:(NSString *)str;
- (void)removeEntry:(NSString *)str;
- (BOOL)containsEntry:(NSString *)str;
- (NSArray *)allEntries;
- (void)flush;
- (void)reload;
@end
