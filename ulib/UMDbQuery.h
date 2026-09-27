 //
//  UMDbQuery.h
//  ulibdb.framework
//
//  Created by Andreas Fink on 26.10.11.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.

#import <ulib/UMObject.h>
#import <ulib/UMDbStorageType.h>
#import <ulib/UMDbQueryCondition.h>
#import <ulib/UMDbFieldDefinitions.h>
#import <ulib/UMDbFieldDefinition.h>
#import <ulib/UMDbTableDefinition.h>

#import <ulib/ulib_config.h>

#import <ulib/UMDbQueryType.h>
#import <ulib/UMDbDriverType.h>
#import <ulib/UMDbQueryCondition.h>
#import <ulib/UMDbQueryPlaceholder.h>
#import <ulib/UMDbTable.h>

#define NEW_OR_CACHED_UMDB_QUERY()  [UMDbQuery queryForFile:__FILE__ line: __LINE__]


@interface UMDbQuery : UMObject
{
    UMDbQueryType   _type;
    NSString        *_instance;
    NSString        *_databaseName;
    UMDbTable       *_table;
    UMDbQueryCondition *_whereCondition;
    NSString        *_grouping;
    NSArray         *_sortByFields;
    NSArray         *_fields;
    NSArray         *_keys;
    int             _limit;
    BOOL            _isInCache;
    UMDbStorageType _storageType;
    NSString        *_primaryKeyName;
    const char      *_cfile;
    long            _cline;
    NSString        *_cacheKey;
    NSString        *_lastSql;
}


@property(readwrite,assign) UMDbQueryType   type;
@property(readwrite,strong) NSString        *instance;
@property(readwrite,strong) NSString        *databaseName;
@property(readwrite,strong) UMDbTable       *table;
@property(readwrite,strong) UMDbQueryCondition *whereCondition;
@property(readwrite,strong) NSString        *grouping;
@property(readwrite,strong) NSArray         *sortByFields;
@property(readwrite,strong) NSArray         *fields;
@property(readwrite,strong) NSArray         *keys;
@property(readwrite,assign) int             limit;
@property(readwrite,assign) BOOL            isInCache;
@property(readwrite,assign) UMDbStorageType storageType;
@property(readwrite,strong) NSString        *primaryKeyName;
@property(readwrite,assign) const char      *cfile;
@property(readwrite,assign) long            cline;
@property(readwrite,strong) NSString        *cacheKey;
@property(readwrite,strong,atomic) NSString *lastSql;

+ (void)initStatics;

+ (UMDbQuery *)queryForFile:(const char *)file line: (const long)line; /* designated allocator */
- (BOOL) returnsResult;
- (void)addToCache;
- (void)addToCacheWithKey:(NSString *)key2;
//- (void)setFieldsFromString:(NSString *)fields;

- (NSString *)sqlForType:(UMDbQueryType)dbQueryType
               forDriver:(UMDbDriverType)dbDriverType
                 session:(UMDbSession *)session
              parameters:(NSArray *)arr
         primaryKeyValue:(id)primaryKeyValue;

- (NSString *)redisForType:(UMDbQueryType)dbQueryType
                 forDriver:(UMDbDriverType)dbDriverType
                   session:(UMDbSession *)session
                parameters:(NSArray *)arr
           primaryKeyValue:(id)primaryKeyValue;

+ (NSArray *)createSql:(NSString *) tn
            withDbType:(UMDbDriverType)dbType
               session:(UMDbSession *)session
      fieldsDefinition:(dbFieldDef *)fieldDef;

+ (NSArray *)createSql:(NSString *)tn
            withDbType:(UMDbDriverType)dbType
               session:(UMDbSession *)session
       tableDefinition:(UMDbTableDefinition *)tableDef;

+ (NSArray *)createArchiveSql:(NSString *)tn
                   withDbType:(UMDbDriverType)dbType
                      session:(UMDbSession *)session
             fieldsDefinition:(dbFieldDef *)fieldDef;

+ (NSArray *)createArchiveSql:(NSString *)tn
                   withDbType:(UMDbDriverType)dbType
                      session:(UMDbSession *)session
              tableDefinition:(UMDbTableDefinition *)tableDef;

+ (NSArray *)createSql:(NSString *) tn
            withDbType:(UMDbDriverType)dbType
               session:(UMDbSession *)session
      fieldsDefinition:(dbFieldDef *)fieldDef
            forArchive:(BOOL)arch;
//+ (NSString *)createSql:(NSString *) tn withDbType:(UMDbDriverType)dbType tableDefinition:(UMDbTableDefinition *)tableDef forArchive:(BOOL)arch;

+ (NSArray *)fieldNamesArrayFromFieldsDefinition:(dbFieldDef *)fieldDef;
+ (NSArray *)fieldNamesArrayFromTableDefinition:(UMDbTableDefinition *)tableDef;

- (NSString *)selectForType:(UMDbDriverType)dbDriverType
                    session:(UMDbSession *)session
                 parameters:(NSArray *)params
            primaryKeyValue:(id)primaryKeyValue;

- (NSString *)selectForType:(UMDbDriverType)dbDriverType
                    session:(UMDbSession *)session
                 parameters:(NSArray *)params
            primaryKeyValue:(id)primaryKeyValue
             whereCondition:(UMDbQueryCondition *)whereCondition1;

- (NSString *)selectByKeyForType:(UMDbDriverType)dbDriverType
                         session:(UMDbSession *)session
                      parameters:(NSArray *)params
                 primaryKeyValue:(id)primaryKeyValue;

- (NSString *)selectByKeyLikeForType:(UMDbDriverType)dbDriverType
                             session:(UMDbSession *)session
                          parameters:(NSArray *)params
                     primaryKeyValue:(id)primaryKeyValue;

- (NSString *)selectByKeyFromListForType:(UMDbDriverType)dbDriverType
                                 session:(UMDbSession *)session
                              parameters:(NSArray *)params
                         primaryKeyValue:(id)primaryKeyValue;

- (NSString *)updateByKeyForType:(UMDbDriverType)dbDriverType
                         session:(UMDbSession *)session
                      parameters:(NSArray *)params
                 primaryKeyValue:(id)primaryKeyValue;

- (NSString *)updateForType:(UMDbDriverType)dbDriverType
                    session:(UMDbSession *)session
                 parameters:(NSArray *)params
            primaryKeyValue:(id)primaryKeyValue
             whereCondition:(UMDbQueryCondition *)whereCondition1;

- (NSString *)updateByKeyLikeForType:(UMDbDriverType)dbDriverType
                             session:(UMDbSession *)session
                          parameters:(NSArray *)params
                     primaryKeyValue:(id)primaryKeyValue;

- (NSString *)insertByKeyForType:(UMDbDriverType)dbDriverType
                         session:(UMDbSession *)session
                      parameters:(NSArray *)params
                 primaryKeyValue:(id)primaryKeyValue;

- (NSString *)deleteForType:(UMDbDriverType)dbDriverType
                    session:(UMDbSession *)session
                 parameters:(NSArray *)params
            primaryKeyValue:(id)primaryKeyValue;

- (NSString *)deleteForType:(UMDbDriverType)dbDriverType
                    session:(UMDbSession *)session
                 parameters:(NSArray *)params
            primaryKeyValue:(id)primaryKeyValue
             whereCondition:(UMDbQueryCondition *)whereCondition1;

- (NSString *)deleteByKeyForType:(UMDbDriverType)dbDriverType
                         session:(UMDbSession *)session
                      parameters:(NSArray *)params
                 primaryKeyValue:(id)primaryKeyValue;

- (NSString *)keyForParameters:(NSArray *)params; /*TODO primary key?!? */

@end

#define ARRAY_FROM_STRING_WITH_COMMA    (s)  ((s) ? [s componentsSeparatedByString:@","] : @[])
#define STRING_WITH_COMMA_FROM_ARRAY(a)  ((a) ? [(a) componentsJoinedByString:@","] : @"")
#define STRING_FROM_DOUBLE64(i)   [NSString stringWithFormat:@"%6.4lf",(double)i]
#define STRING_FROM_DOUBLE(i)   [NSString stringWithFormat:@"%lf",(double)i]
#define STRING_FROM_INT(i)      [NSString stringWithFormat:@"%ld",(long)i]
#define STRING_FROM_NUMBER(i)      [NSString stringWithFormat:@"%ld",(long)i.intValue]
#define STRING_FROM_DATE(d)      ( d ? [d stringValue] : [NSDate zeroDateString])
#define STRING_FROM_UNSIGNEDLONG(i)      [NSString stringWithFormat:@"%lu",(unsigned long)i]
#define STRING_01_FROM_BOOL(i)  ((i) ? @"1" : @"0")
#define STRING_YN_FROM_BOOL(i)  ((i) ? @"YES" : @"NO")
#define STRING_NONEMPTY(a)       ((a) ? (a) : @"")
#define STRING_SPACEEMPTY(a)       ((a) ? (a) : @" ")
#define STRING_NONEMPTY_ARRAY(a) ((a) ? (a) : @[])
#define STRING_FROM_DATA(a)      ((a) ? [(a) hexString]: @"")
#define STRING_FROM_CSTRING(a)   ((a) ? [NSString stringWithUTF8String:(a)] : @"")


