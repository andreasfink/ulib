//
//  UMConfigMacroHelper.m
//  ulib
//
//  Created by Andreas Fink on 26.11.2026.
//

#import "UMConfigObject.h"
#import "UMConfigMacroHelper.h"

/* -------------------------------------------------------------------------------------------------------------------------------- */
/*  appendConfig functions  */
/* -------------------------------------------------------------------------------------------------------------------------------- */

void ulib_config_appendConfig_BOOLEAN(NSMutableString *str,const char *name,NSNumber *value,const char *dbname,int tag,const char *options)
{
    if(value!=NULL)
    {
        [str appendFormat:@"%s=%@\n",name,value.boolValue ? @"YES": @"NO"];
    }
}

void ulib_config_appendConfig_REAL(NSMutableString *str,const char *name,NSNumber *value,const char *dbname,int tag,const char *options)
{
    if(value!=NULL)
    {
        [str appendFormat:@"%s=%lf\n",name,value.doubleValue];
    }
}

void ulib_config_appendConfig_INTEGER(NSMutableString *str,const char *name,NSNumber *value,const char *dbname,int tag,const char *options)
{
    if(value!=NULL)
    {
        [str appendFormat:@"%s=%d\n",name,value.intValue];
    }
}

void ulib_config_appendConfig_STRING(NSMutableString *str,const char *name,NSString *value,const char *dbname,int tag,const char *options)
{
    if(value!=NULL)
    {
        [str appendFormat:@"%s=%@\n",name,value];
    }
}

void ulib_config_appendConfig_HEXDATA(NSMutableString *str,const char *name,NSData *value,const char *dbname,int tag,const char *options)
{
    if(value!=NULL)
    {
        [str appendFormat:@"%s=%@\n",name,value.hexString];
    }
}

void ulib_config_appendConfig_FILTERED_STRING(NSMutableString *str,const char *name,NSString *value,const char *dbname,int tag,const char *options)
{
    if(value!=NULL)
    {
        [str appendFormat:@"%s=%@\n",name,[UMConfigObject filterName:value.stringValue]];
    }
}

void ulib_config_appendConfig_DATE(NSMutableString *str,const char *name,NSDate *value,const char *dbname,int tag,const char *options)
{
    if(value!=NULL)
    {
        [str appendFormat:@"%s=%@\n",name,value.stringValue];
    }
}

void ulib_config_appendConfig_ARRAY_VERBOSE(NSMutableString *str,const char *name,NSArray *array,const char *dbname,int tag,const char *options)
{
    if(array!=NULL)
    {
        NSUInteger n= [array count];
        for(NSUInteger i=0;i<n;i++)
        {
            [str appendFormat:@"%s=%@\n",name,array[i]];
        }
    }
}

void ulib_config_appendConfig_ARRAY_COMPACT(NSMutableString *str,const char *name,NSArray *array,const char *dbname,int tag,const char *options)
{
    if(array!=NULL)
    {
        NSUInteger n = [array count];
        for(NSUInteger i=0;i<n;i++)
        {
            if(i==0)
            {
                [str appendFormat:@"%s=%@",name,array[i]];
            }
            else
            {
                [str appendFormat:@";%@",array[i]];
            }
        }
        [str appendString:@"\n"];
    }
}

/* -------------------------------------------------------------------------------------------------------------------------------- */
/*  appendDict functions  */
/* -------------------------------------------------------------------------------------------------------------------------------- */

void ulib_config_appendDict_BOOLEAN(UMSynchronizedSortedDictionary *dict,const char *name,NSNumber *value,const char *dbname,int tag,const char *options)
{
    if(value!=NULL)
    {
        dict[@(name)] = @(value.boolValue);
    }
}

void ulib_config_appendDict_REAL(UMSynchronizedSortedDictionary *dict,const char *name,NSNumber *value,const char *dbname,int tag,const char *options)
{
    if(value!=NULL)
    {
        dict[@(name)] = @(value.doubleValue);
    }
}

void ulib_config_appendDict_INTEGER(UMSynchronizedSortedDictionary *dict,const char *name,NSNumber *value,const char *dbname,int tag,const char *options)

{
    if(value!=NULL)
    {
        dict[@(name)] = @(value.intValue);
    }
}

void ulib_config_appendDict_STRING(UMSynchronizedSortedDictionary *dict,const char *name,NSString *value,const char *dbname,int tag,const char *options)
{
    if(value!=NULL)
    {
        dict[@(name)] = value.stringValue;
    }
}

void ulib_config_appendDict_HEXDATA(UMSynchronizedSortedDictionary *dict,const char *name,NSData *value,const char *dbname,int tag,const char *options)
{
    if(value!=NULL)
    {
        dict[@(name)] = value.stringValue.hexString;
    }
}

void ulib_config_appendDict_FILTERED_STRING(UMSynchronizedSortedDictionary *dict,const char *name,NSString *value,const char *dbname,int tag,const char *options)
{
    if(value!=NULL)
    {
        dict[@(name)] = [UMConfigObject filterName:value];
    }
}

void ulib_config_appendDict_DATE(UMSynchronizedSortedDictionary *dict,const char *name,NSDate *value,const char *dbname,int tag,const char *options)
{
    if(value!=NULL)
    {
        dict[@(name)] = value.stringValue;
    }
}


void ulib_config_appendDict_ARRAY_COMPACT(UMSynchronizedSortedDictionary *dict,const char *name,NSArray *array,const char *dbname,int tag,const char *options)
{
    if(array!=NULL)
    {
        dict[@(name)] = array;
    }
}


void ulib_config_appendDict_ARRAY_VERBOSE(UMSynchronizedSortedDictionary *dict,const char *name,NSArray *array,const char *dbname,int tag,const char *options)
{
    if(array!=NULL)
    {
        dict[@(name)] = array;
    }
}


/* -------------------------------------------------------------------------------------------------------------------------------- */
/*  setDict functions  */
/* -------------------------------------------------------------------------------------------------------------------------------- */


NSNumber *ulib_config_setConfigFromDict_BOOLEAN(NSDictionary *o,const char *name,const char *dbname,int tag,const char *options)
{
    NSNumber *value;
    if(o[@(name)]!=NULL)
    {
        id obj = o[@(name)];
        if([obj isKindOfClass:[NSString class]])
        {
            value = [NSNumber numberWithBool:[obj boolValue]];
        }
        else if([obj isKindOfClass:[NSArray class]])
        {
            value = [NSNumber numberWithBool:[obj[0] boolValue]];
        }
        else if([obj isKindOfClass:[NSNumber class]])
        {
            value = [NSNumber numberWithBool:[obj boolValue]];
        }
    }
    return value;
}

NSNumber *ulib_config_setConfigFromDict_REAL(NSDictionary *o,const char *name,const char *dbname,int tag,const char *options)
{
    NSNumber *value;
    if(o[@(name)]!=NULL)
    {
        id obj = o[@(name)];
        if([obj isKindOfClass:[NSString class]])
        {
            value = [NSNumber numberWithDouble:[obj doubleValue]];
        }
        else if([obj isKindOfClass:[NSArray class]])
        {
            value = [NSNumber numberWithDouble:[obj[0] doubleValue]];
        }
        else if([obj isKindOfClass:[NSNumber class]])
        {
            value = [NSNumber numberWithDouble:[obj doubleValue]];
        }
    }
    return value;
}


NSNumber *ulib_config_setConfigFromDict_INTEGER(NSDictionary *o,const char *name,const char *dbname,int tag,const char *options)
{
    NSNumber *value;
    if(o[@(name)]!=NULL)
    {
        id obj = o[@(name)];
        if([obj isKindOfClass:[NSString class]])
        {
            NSString *str = (NSString *)obj;
            value = @([str intergerValueSupportingHex]);
        }
        else if([obj isKindOfClass:[NSArray class]])
        {
            value = [NSNumber numberWithInt:[obj[0] intValue]];
        }
        else if([obj isKindOfClass:[NSNumber class]])
        {
            value = [NSNumber numberWithInt:[obj intValue]];
        }
    }
    return value;
}

NSString *ulib_config_setConfigFromDict_STRING(NSDictionary *o,const char *name,const char *dbname,int tag,const char *options)
{
    NSString *value;
    if(o[@(name)]!=NULL)
    {
        id obj = o[@(name)];
        if([obj isKindOfClass:[NSString class]])
        {
            value = obj;
        }
        else if([obj isKindOfClass:[NSArray class]])
        {
            value = [((NSArray *)obj) componentsJoinedByString:@";"];
        }
    }
    return value;
}

NSString *ulib_config_setConfigFromDict_FILTERED_STRING(NSDictionary *o,const char *name,const char *dbname,int tag,const char *options)
{
    NSString *value;
    if(o[@(name)]!=NULL)
    {
        id o0 = o[@(name)];
        if([o0 isKindOfClass:[NSString class]])
        {
            value = [UMConfigObject filterName:o0];
        }
        else if([o0 isKindOfClass:[NSArray class]])
        {
            NSMutableArray *a2 = [[NSMutableArray alloc]init];
            id o1;
            NSArray *arr = (NSArray *)o0;
            for(o1 in arr)
            {
                if([o1 isKindOfClass:[NSString class]])
                {
                    NSString *s = (NSString *)o1;
                    [a2 addObject: [UMConfigObject filterName:s]];
                }
                else if([o1 isKindOfClass:[NSNumber class]])
                {
                    NSNumber *n = (NSNumber *)o1;
                    [a2 addObject: n.stringValue];
                }
            }
            value = [((NSArray *)a2) componentsJoinedByString:@";"];
        }
    }
    return value;
}

NSDate *ulib_config_setConfigFromDict_DATE(NSDictionary *o,const char *name,const char *dbname,int tag,const char *options)
{
    NSDate *value;
    
    if(o[@(name)]!=NULL)
    {
        id obj = o[@(name)];
        if([obj isKindOfClass:[NSString class]])
        {
            value = [obj dateValue];
        }
        else if([obj isKindOfClass:[NSDate class]])
        {
            value = obj;
        }
        else if([obj isKindOfClass:[NSNumber class]])
        {
            value = [[NSDate alloc]initWithTimeIntervalSinceReferenceDate:[obj doubleValue]]; \
        }
    }
    return value;
}


NSArray *ulib_config_setConfigFromDict_ARRAY_COMPACT(NSDictionary *o,const char *name,const char *dbname,int tag,const char *options)
{
    NSArray *value;
    if(o[@(name)]!=NULL)
    {
        id obj = o[@(name)];
        if([obj isKindOfClass:[NSString class]])
        {
            value = [((NSString *)obj) componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" \r\n\t;"]];
        }
        else if([obj isKindOfClass:[NSArray class]])
        {
            value = obj;
        }
    }
    return value;
}

NSArray *ulib_config_setConfigFromDict_ARRAY_VERBOSE(NSDictionary *o,const char *name,const char *dbname,int tag,const char *options)
{
    NSArray *value;
    if(o[@(name)]!=NULL)
    {
        id obj = o[@(name)];
        if([obj isKindOfClass:[NSString class]])
        {
            value = [((NSString *)obj) componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" \r\n\t;"]];
        }
        else if([obj isKindOfClass:[NSArray class]])
        {
            value = obj;
        }
    }
    return value;
}

NSData *ulib_config_setConfigFromDict_HEXDATA(NSDictionary *o,const char *name,const char *dbname,int tag,const char *options)
{
    NSData *value;
    if(o[@(name)]!=NULL)
    {
        id obj = o[@(name)];
        if([obj isKindOfClass:[NSString class]])
        {
            NSString *s = (NSString *)obj;
            value = [s unhexedData];
        }
    }
    return value;
}
