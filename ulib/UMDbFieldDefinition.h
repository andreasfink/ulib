//
//  UMDbFieldDefinition.h
//  ulibdb
//
//  Created by Andreas Fink on 13.05.14.
//
//

#import <ulib/UMObject.h>
#import <ulib/UMDbFieldDefinitions.h>

typedef enum UMDbFieldType
{
    UMDB_FIELD_TYPE_NULL,
    UMDB_FIELD_TYPE_VARCHAR,
    UMDB_FIELD_TYPE_SMALL_INTEGER,
    UMDB_FIELD_TYPE_INTEGER,
    UMDB_FIELD_TYPE_BIG_INTEGER,
    UMDB_FIELD_TYPE_TEXT,
    UMDB_FIELD_TYPE_TIMESTAMP_AS_STRING,
    UMDB_FIELD_TYPE_NUMERIC,
    UMDB_FIELD_TYPE_BLOB,
    UMDB_FIELD_TYPE_END,
} UMDbFieldType;

@interface UMDbFieldDefinition : UMObject
{
    NSString        *fieldName;
    NSString        *defaultValue;
    BOOL            canBeNull;
    BOOL            isIndexed;
    BOOL            isPrimaryIndex;
    BOOL            isIndexedInArchive;
    UMDbFieldType   fieldType;
    NSInteger       fieldSize;
    NSInteger       fieldDecimals;
    NSInteger             tagId;
    SEL             setter;
    SEL             getter;
    NSString        *setterName;
    NSString        *getterName;
}

@property(readwrite,strong) NSString        *fieldName;
@property(readwrite,strong) NSString        *defaultValue;
@property(readwrite,assign) BOOL            canBeNull;
@property(readwrite,assign) BOOL            isIndexed;
@property(readwrite,assign) BOOL            isPrimaryIndex;
@property(readwrite,assign) BOOL            isIndexedInArchive;
@property(readwrite,assign) UMDbFieldType   fieldType;
@property(readwrite,assign) NSInteger       fieldSize;
@property(readwrite,assign) NSInteger       fieldDecimals;
@property(readwrite,assign) NSInteger             tagId;
@property(readwrite,assign) SEL             setter;
@property(readwrite,assign) SEL             getter;
@property(readwrite,strong) NSString        *setterName;
@property(readwrite,strong) NSString        *getterName;

- (UMDbFieldDefinition *)init;
- (UMDbFieldDefinition *)initWithOldFieldDef:(dbFieldDef *)fdef;

- (UMDbFieldDefinition *)initWithVarchar:(NSString *)name
                                    size:(int)size
                               canBeNull:(BOOL)nullAllowed
                                 indexed:(BOOL)indexed
                                 primary:(BOOL)primary
                                     tag:(int)tag;

- (UMDbFieldDefinition *)initWithInteger:(NSString *)name
                               canBeNull:(BOOL)nullAllowed
                                 indexed:(BOOL)indexed
                                 primary:(BOOL)primary
                                     tag:(int)tag;


- (NSString *)asJson;
- (NSDictionary *)asDictionary;

- (void)setFromJson:(NSString *)json;
- (void)setFromDictionary:(NSDictionary *)dict;

@end



