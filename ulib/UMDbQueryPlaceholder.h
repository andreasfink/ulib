//
//  UMDbQueryPlaceholder.h
//  ulibdb.framework
//
//  Created by Andreas Fink on 27.10.11.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.

#import <ulib/ulib.h>
#import <ulib/UMDbDriverType.h>

@class UMDbQuery;
@class UMDbSession;

typedef enum UMDbPlaceholderType
{
    UMDBPLACEHOLDER_TYPE_NULL,
    UMDBPLACEHOLDER_TYPE_PARAM,
    UMDBPLACEHOLDER_TYPE_TEXT,
    UMDBPLACEHOLDER_TYPE_INTEGER,
    UMDBPLACEHOLDER_TYPE_FIELD,
    UMDBPLACEHOLDER_TYPE_PRIMARY_KEY_NAME,
    UMDBPLACEHOLDER_TYPE_PRIMARY_KEY_VALUE,
} UMDbPlaceholderType;

@interface UMDbQueryPlaceholder : UMObject
{
    UMDbPlaceholderType type;
    int         index;
    NSString    *text;
}

@property(readwrite,assign) UMDbPlaceholderType type;
@property(readwrite,assign) int index;
@property(readwrite,strong) NSString *text;

- (UMDbQueryPlaceholder *)initWithInteger:(int)i;
- (UMDbQueryPlaceholder *)initWithString:(NSString *)string;
- (UMDbQueryPlaceholder *)initWithField:(NSString *)string;
- (UMDbQueryPlaceholder *)initWithParameterIndex:(int)index;
- (UMDbQueryPlaceholder *)initWithPrimaryKeyValue;
- (UMDbQueryPlaceholder *)initWithPrimaryKeyName;

+ (UMDbQueryPlaceholder *)placeholderInteger:(int)i;
+ (UMDbQueryPlaceholder *)placeholderString:(NSString *)string;
+ (UMDbQueryPlaceholder *)placeholderField:(NSString *)string;
+ (UMDbQueryPlaceholder *)placeholderParameterIndex:(int)i;
+ (UMDbQueryPlaceholder *)placeholderPrimaryKeyName;
+ (UMDbQueryPlaceholder *)placeholderPrimaryKeyValue;


- (NSString *) sqlForQueryLeft:(UMDbQuery *)query
                    parameters:(NSArray *)params
                        dbType:(UMDbDriverType)dbType
               primaryKeyValue:(id)primaryKeyValue;

- (NSString *) sqlForQueryLeft:(UMDbQuery *)query
                    parameters:(NSArray *)params
                        dbType:(UMDbDriverType)dbType
                       session:(UMDbSession *)session
               primaryKeyValue:(id)primaryKeyValue;

- (NSString *) sqlForQueryRight:(UMDbQuery *)query
                     parameters:(NSArray *)params
                         dbType:(UMDbDriverType)dbType
                primaryKeyValue:(id)primaryKeyValue;

- (NSString *) sqlForQueryRight:(UMDbQuery *)query
                     parameters:(NSArray *)params
                         dbType:(UMDbDriverType)dbType
                        session:(UMDbSession *)session
                primaryKeyValue:(id)primaryKeyValue;

@end
