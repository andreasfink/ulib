//
//  UMASN1NamedList.h
//  ulibasn1
//
//  Created by Andreas Fink on 19.05.2025.
//  Copyright © 2025 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulibasn1/UMASN1Sequence.h>

@interface UMASN1NamedList : UMASN1Sequence
{
    NSString                        *_name;
    NSString                        *_path;
    BOOL                            _dirty;
    UMSynchronizedSortedDictionary  *_namedlistEntries;
    UMMutex                         *_namedListLock;
}

@property(readwrite,strong,atomic)  NSString            *name;
@property(readwrite,strong,atomic)  NSString            *path;
@property(readwrite,assign,atomic)  BOOL                dirty;
@property(readwrite,strong,atomic)  UMMutex             *namedListLock;


- (UMASN1NamedList *)initWithDirectory:(NSString *)dir name:(NSString *)name;
- (UMASN1NamedList *)initWithPath:(NSString *)path name:(NSString *)name;
- (void)addEntry:(NSString *)str;
- (void)removeEntry:(NSString *)str;
- (BOOL)containsEntry:(NSString *)str;
- (NSArray *)allEntries;
- (void)flush;
- (void)reload;
- (void)dump;
- (NSString *)description;

@end
