//
//  UMConfigObject.h
//  ulib
//
//  Created by Andreas Fink on 26.11.2026.
//

#import <ulib/UMObject.h>
@class UMSynchronizedSortedDictionary;

@interface UMConfigObject : UMObject
{
    BOOL            _dirty;
    NSString         *_name;
    NSString         *_oldName;
    NSNumber         *_enabled;
    NSNumber         *_logLevel;
    NSString         *_logFile;
    NSArray<NSString *>*_comments;
    NSString         *_objectDescription;
    NSMutableArray<UMConfigObject *> *_subEntries;
    BOOL            _nameChanged;
    NSNumber        *_concurrentTasks;
}

@property(readwrite,strong,atomic)  NSString        *name;
@property(readwrite,strong,atomic)  NSNumber        *enabled;
@property(readwrite,strong,atomic)  NSNumber        *logLevel;
@property(readwrite,strong,atomic)  NSString        *logFile;
@property(readwrite,strong,atomic)  NSArray         *comments;
@property(readwrite,strong,atomic)  NSString        *objectDescription; /*we have to name this differently due to [NSObject description] */
@property(readwrite,strong,atomic)  NSMutableArray<UMConfigObject *> *subEntries;
@property(readwrite,assign,atomic)  BOOL            nameChanged;
@property(readwrite,strong,atomic)  NSNumber        *concurrentTasks;

- (BOOL) isDirty;
- (void) setDirty:(BOOL)d;

- (UMConfigObject *)initWithConfig:(NSDictionary *)dict;
- (UMConfigObject *)initWithString:(NSString *)s;

- (NSString *)configString;
- (NSString *)groupName;

- (void)appendConfigToString:(NSMutableString *)o;
- (void)appendConfigToString:(NSMutableString *)o withoutName:(BOOL)withoutName;

- (UMSynchronizedSortedDictionary *)config;
- (UMSynchronizedSortedDictionary *)configWithoutName:(BOOL)withoutName;

- (void)setConfig:(NSDictionary *)config;
- (void)setSuperConfig:(NSDictionary *)config;

+ (NSString *)filterName:(NSString *)str;
- (UMConfigObject *)copyWithZone:(NSZone *)zone;
- (void)addSubEntry:(UMConfigObject *)obj;

- (NSArray<NSDictionary *> *)subConfigs;
- (id)proxyForJson;
- (NSString *)description;
- (BOOL)requiresName;

@end
