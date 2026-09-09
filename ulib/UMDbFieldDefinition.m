//
//  UMDbFieldDefinition.m
//  ulibdb
//
//  Created by Andreas Fink on 13.05.14.
//
//

#import <ulib/UMDbFieldDefinition.h>
#import <ulib/ulib_config.h>
#import <ulib/UMJsonWriter.h>
#import <ulib/UMJsonParser.h>
@implementation UMDbFieldDefinition

@synthesize fieldName;
@synthesize defaultValue;
@synthesize canBeNull;
@synthesize isIndexed;
@synthesize isPrimaryIndex;
@synthesize isIndexedInArchive;
@synthesize fieldType;
@synthesize fieldSize;
@synthesize fieldDecimals;
@synthesize tagId;
@synthesize setter;
@synthesize getter;
@synthesize setterName;
@synthesize getterName;

- (UMDbFieldDefinition *)init
{
    self=[super init];
    if(self)
    {
        fieldName = NULL;
        canBeNull = NO;
        isIndexed = NO;
        isPrimaryIndex = NO;
        isIndexedInArchive = NO;
        fieldType = UMDB_FIELD_TYPE_NULL;
        fieldSize = 0;
        fieldDecimals = 0;
        tagId = 0;
    }
    return self;
}


- (UMDbFieldDefinition *)initWithVarchar:(NSString *)name
                                    size:(int)size
                               canBeNull:(BOOL)nullAllowed
                                 indexed:(BOOL)indexed
                                 primary:(BOOL)primary
                                     tag:(int)tag
{
    self=[super init];
    if(self)
    {
        fieldName = name;
        canBeNull = YES;
        isIndexed = indexed;
        isPrimaryIndex = primary;
        canBeNull = nullAllowed;
        fieldSize = size;
        tagId = tag;
    }
    return self;
}
- (UMDbFieldDefinition *)initWithInteger:(NSString *)name
                               canBeNull:(BOOL)nullAllowed
                                 indexed:(BOOL)indexed
                                 primary:(BOOL)primary
                                     tag:(int)tag
{
    self=[super init];
    if(self)
    {
        fieldName = name;
        isIndexed = indexed;
        isPrimaryIndex = primary;
        canBeNull = nullAllowed;
        tagId = tag;
    }
    return self;
}

- (UMDbFieldDefinition *)initWithOldFieldDef:(dbFieldDef *)fdef
{
    self=[super init];
    if(self)
    {
        fieldName = @(fdef->name);
        canBeNull = fdef->canBeNull;
        switch(fdef->indexed)
        {
            case DB_NOT_INDEXED:
                isPrimaryIndex = NO;
                isIndexed = NO;
                isIndexedInArchive = NO;
                break;
            case DB_PRIMARY_INDEX:
                isPrimaryIndex = YES;
                isIndexed = NO;
                isIndexedInArchive = NO;
                break;
            case DB_INDEXED:
                isPrimaryIndex = NO;
                isIndexed = YES;
                isIndexedInArchive = YES;
                break;
            case DB_INDEXED_BUT_NOT_FOR_ARCHIVE:
                isPrimaryIndex = NO;
                isIndexed = YES;
                isIndexedInArchive = NO;
                break;
        }
        switch(fdef->fieldType)
        {
            case DB_FIELD_TYPE_VARCHAR:
                fieldType = UMDB_FIELD_TYPE_VARCHAR;
                break;
            case DB_FIELD_TYPE_SMALL_INTEGER:
                fieldType = UMDB_FIELD_TYPE_SMALL_INTEGER;
                break;
            case DB_FIELD_TYPE_INTEGER:
                fieldType = UMDB_FIELD_TYPE_INTEGER;
                break;
            case DB_FIELD_TYPE_BIG_INTEGER:
                fieldType = UMDB_FIELD_TYPE_BIG_INTEGER;
                break;
            case DB_FIELD_TYPE_TEXT:
                fieldType = UMDB_FIELD_TYPE_TEXT;
                break;
            case DB_FIELD_TYPE_TIMESTAMP_AS_STRING:
                fieldType = UMDB_FIELD_TYPE_TIMESTAMP_AS_STRING;
                break;
            case DB_FIELD_TYPE_NUMERIC:
                fieldType = UMDB_FIELD_TYPE_NUMERIC;
                break;
            case DB_FIELD_TYPE_BLOB:
                fieldType = UMDB_FIELD_TYPE_BLOB;
                break;
            default:
                fieldType = UMDB_FIELD_TYPE_NULL;
                break;
        }

        fieldSize = fdef->fieldSize;
        fieldDecimals = fdef->fieldDecimals;
        tagId = fdef->tagId;
        setter = fdef->setter;
        getter = fdef->getter;
    }
    return self;
}

- (NSString *)asJson
{
    NSDictionary *dict = [self asDictionary];
    UMJsonWriter *writer = [[UMJsonWriter alloc]init];
    NSString *s = [writer stringWithObject:dict];
    return s;
}

#define DICTKEY_FIELD_NAME          @"name"
#define DICTKEY_DEFAULT_VALUE       @"default"
#define DICTKEY_CAN_BE_NULL         @"null"
#define DICTKEY_INDEXED             @"indexed"
#define DICTKEY_PRIMARY_KEY         @"primary"
#define DICTKEY_INDEXED_IN_ARCHIVE  @"archindex"
#define DICTKEY_FIELD_TYPE          @"type"
#define DICTKEY_FIELD_SIZE          @"size"
#define DICTKEY_FIELD_DECIMALS      @"decimals"
#define DICTKEY_TAG                 @"tag"
#define DICTKEY_GETTERNAME          @"gettername"
#define DICTKEY_SETTERNAME          @"settername"

- (NSDictionary *)asDictionary
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    
    dict[DICTKEY_FIELD_NAME] = self.fieldName;
    dict[DICTKEY_DEFAULT_VALUE] = self.defaultValue;
    if(self.canBeNull)
    {
        dict[DICTKEY_CAN_BE_NULL] = @"YES";
    }
    else
    {
        dict[DICTKEY_CAN_BE_NULL] = @"NO";
    }

    if(self.isIndexed)
    {
        dict[DICTKEY_INDEXED] = @"YES";
    }
    else
    {
        dict[DICTKEY_INDEXED] = @"NO";
    }

    if(self.isPrimaryIndex)
    {
        dict[DICTKEY_PRIMARY_KEY] = @"YES";
    }
    else
    {
        dict[DICTKEY_PRIMARY_KEY] = @"NO";
    }
    
    if(self.isIndexedInArchive)
    {
        dict[DICTKEY_INDEXED_IN_ARCHIVE] = @"YES";
    }
    else
    {
        dict[DICTKEY_INDEXED_IN_ARCHIVE] = @"NO";
    }

    
    switch(self.fieldType)
    {
        case UMDB_FIELD_TYPE_VARCHAR:
            dict[DICTKEY_FIELD_TYPE] = @"STRING";
            break;
        case UMDB_FIELD_TYPE_SMALL_INTEGER:
            dict[DICTKEY_FIELD_TYPE] = @"SMALLINT";
            break;
        case UMDB_FIELD_TYPE_INTEGER:
            dict[DICTKEY_FIELD_TYPE] = @"INT";
            break;
        case UMDB_FIELD_TYPE_BIG_INTEGER:
            dict[DICTKEY_FIELD_TYPE] = @"BIGINT";
            break;
        case UMDB_FIELD_TYPE_TEXT:
            dict[DICTKEY_FIELD_TYPE] = @"TEXT";
            break;
        case UMDB_FIELD_TYPE_TIMESTAMP_AS_STRING:
            dict[DICTKEY_FIELD_TYPE] = @"TIMESTAMP";
            break;
        case UMDB_FIELD_TYPE_NUMERIC:
            dict[DICTKEY_FIELD_TYPE] = @"NUMERIC";
            break;
        case UMDB_FIELD_TYPE_BLOB:
            dict[DICTKEY_FIELD_TYPE] = @"BLOB";
            break;
        default:
            dict[DICTKEY_FIELD_TYPE] = @"UNDEFINED";
            break;
    }
    dict[DICTKEY_FIELD_SIZE] = [NSString stringWithFormat:@"%ld",(long)self.fieldSize];
    dict[DICTKEY_FIELD_DECIMALS] = [NSString stringWithFormat:@"%ld",(long)self.fieldDecimals];
    dict[DICTKEY_TAG] = [NSString stringWithFormat:@"%ld",(long)self.tagId];
    if(self.getterName)
    {
        dict[DICTKEY_GETTERNAME] = self.getterName;
    }
    if(self.setterName)
    {
        dict[DICTKEY_SETTERNAME] = self.setterName;
    }
    return dict;
}

- (void)setFromJson:(NSString *)json
{
    UMJsonParser *parser = [[UMJsonParser alloc]init];
    NSDictionary *dict = [parser objectWithString:json];
    [self setFromDictionary:dict];
}

- (void)setFromDictionary:(NSDictionary *)dict
{
    id value = dict[DICTKEY_FIELD_NAME];
    if(value)
    {
        self.fieldName = value;
    }

    value = dict[DICTKEY_DEFAULT_VALUE];
    if(value)
    {
        self.defaultValue = value;
    }
    
    value = dict[DICTKEY_CAN_BE_NULL];
    if(value)
    {
        self.canBeNull = ([value isEqualToString:@"YES"]) ? YES : NO;
    }
    
    value = dict[DICTKEY_INDEXED];
    if(value)
    {
        self.isIndexed = ([value isEqualToString:@"YES"]) ? YES : NO;
    }
    
    value = dict[DICTKEY_PRIMARY_KEY];
    if(value)
    {
        self.isPrimaryIndex = ([value isEqualToString:@"YES"]) ? YES : NO;
    }

    value = dict[DICTKEY_INDEXED_IN_ARCHIVE];
    if(value)
    {
        self.isIndexedInArchive = ([value isEqualToString:@"YES"]) ? YES : NO;
    }
    
    value = dict[DICTKEY_FIELD_TYPE];
    if(value)
    {
        if([value isEqualToString:@"STRING"])
        {
            self.fieldType = UMDB_FIELD_TYPE_VARCHAR;
        }
        else if([value isEqualToString:@"SMALLINT"])
        {
            self.fieldType = UMDB_FIELD_TYPE_SMALL_INTEGER;
        }
        else if([value isEqualToString:@"INT"])
        {
            self.fieldType = UMDB_FIELD_TYPE_INTEGER;
        }
        else if([value isEqualToString:@"BIGINT"])
        {
            self.fieldType = UMDB_FIELD_TYPE_BIG_INTEGER;
        }
        else if([value isEqualToString:@"TEXT"])
        {
            self.fieldType = UMDB_FIELD_TYPE_TEXT;
        }
        else if([value isEqualToString:@"TIMESTAMP"])
        {
            self.fieldType = UMDB_FIELD_TYPE_TIMESTAMP_AS_STRING;
        }
        else if([value isEqualToString:@"BLOB"])
        {
            self.fieldType = UMDB_FIELD_TYPE_BLOB;
        }
    }

    value = dict[DICTKEY_FIELD_SIZE];
    if([value isKindOfClass:[NSString class]])
    {
        NSString *s = (NSString *)value;
        self.fieldSize = [s integerValue];
    }

    value = dict[DICTKEY_FIELD_DECIMALS];
    if([value isKindOfClass:[NSString class]])
    {
        NSString *s = (NSString *)value;
        self.fieldDecimals = [s integerValue];
    }
 
    value = dict[DICTKEY_TAG];
    if([value isKindOfClass:[NSString class]])
    {
        NSString *s = (NSString *)value;
        self.tagId = [s integerValue];
    }
    else if([value isKindOfClass:[NSNumber class]])
    {
        NSNumber *nr = (NSNumber *)value;
        self.tagId = [nr integerValue];
    }
    
    value = dict[DICTKEY_GETTERNAME];
    if(value)
    {
        self.getterName = value;
    }
    value = dict[DICTKEY_SETTERNAME];
    if(value)
    {
        self.setterName = value;
    }

}
@end
