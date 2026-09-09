//
//  UMDbTableDefinition.m
//  ulibdb
//
//  Created by Andreas Fink on 13.05.14.
//
//

#import "UMDbTableDefinition.h"
#import "UMDbFieldDefinition.h"

@implementation UMDbTableDefinition

@synthesize defaultTableName;

- (UMDbFieldDefinition *)getFieldDef:(int)i
{
    @synchronized(fieldDefs)
    {
        if (([fieldDefs count] < i) || (i < 0))
        {
            return NULL;
        }
        UMDbFieldDefinition *f = fieldDefs[i];
        return f;
    }
}

- (void)addFieldDef:(UMDbFieldDefinition *)f
{
    @synchronized(fieldDefs)
    {
        [fieldDefs addObject:f];
    }
}

- (UMDbTableDefinition *)init
{
    self=[super init];
    if(self)
    {
        fieldDefs = [[NSMutableArray alloc]init];
    }
    return self;
}


- (UMDbTableDefinition *)initWithOldFieldsDef:(dbFieldDef *)fdef
{
    self=[super init];
    if(self)
    {
        fieldDefs = [[NSMutableArray alloc]init];
        int i = 0;
        dbFieldDef *f = &fdef[i++];
        while(f && f->name[0] !='\0' && f->fieldType != DB_FIELD_TYPE_END)
        {
            UMDbFieldDefinition *field = [[UMDbFieldDefinition alloc]initWithOldFieldDef:f];
            [fieldDefs addObject:field];
            f = &fdef[i++];
        }
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

- (NSDictionary *)asDictionary
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];

    @synchronized(fieldDefs)
    {
        int i;
        int n = (int)[fieldDefs count];
        for (i=0;i<n;i++)
        {
            UMDbFieldDefinition *f = fieldDefs[i];
            
            dict[[NSString stringWithFormat:@"%d",i]] = [f asDictionary];
        }
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
    int i=0;
    id value = NULL;
    do
    {
        NSString *key = [NSString stringWithFormat:@"%d",i];
        value = dict[key];
        if(value)
        {
            if([value isKindOfClass:[NSDictionary class]])
            {
                UMDbFieldDefinition *f = [[UMDbFieldDefinition alloc]init];
                [f setFromDictionary:value];
                [fieldDefs addObject:f];
            }
            else if([value isKindOfClass:[NSString class]])
            {
                UMDbFieldDefinition *f = [[UMDbFieldDefinition alloc]init];
                [f setFromJson:value];
                [fieldDefs addObject:f];
            }
        }
        i++;
    } while(value);
}

- (NSArray *)fieldNames
{
    @synchronized(fieldDefs)
    {
        NSMutableArray *fieldNames = [[NSMutableArray alloc]init];
        int n = (int)fieldDefs.count;
        int i;
        for(i=0;i<n;i++)
        {
            UMDbFieldDefinition *fd = fieldDefs[i];
            [fieldNames addObject:fd.fieldName];
        }
        return fieldNames;
    }
}
@end
