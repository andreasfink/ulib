//
//  UMDbTableDefinition.h
//  ulibdb
//
//  Created by Andreas Fink on 13.05.14.
//
//

#import <ulib/UMObject.h>
#import <ulib/UMDbFieldDefinitions.h>

@class UMDbFieldDefinition;

@interface UMDbTableDefinition : UMObject
{
    NSMutableArray *fieldDefs;
    NSString *defaultTableName;
}

@property (readwrite,strong) NSString *defaultTableName;

- (UMDbFieldDefinition *)getFieldDef:(int)i;
- (void)addFieldDef:(UMDbFieldDefinition *)f;
- (UMDbTableDefinition *)initWithOldFieldsDef:(dbFieldDef *)fdef;

- (NSString *)asJson;
- (NSDictionary *)asDictionary;
- (void)setFromJson:(NSString *)json;
- (void)setFromDictionary:(NSDictionary *)dict;
- (NSArray *)fieldNames;

@end
