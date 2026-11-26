//
//  UMConfigObject.m
//  ulib
//
//  Created by Andreas Fink on 26.11.2026.
//


#import <ulib/UMConfigObject.h>
#import <ulib/UMConfigMacroHelper.h>

@implementation UMConfigObject

- (BOOL) isDirty
{
    return _dirty;
}

- (void)setDirty:(BOOL)d
{
    _dirty = d;
}

- (NSString *)groupName
{
    return @"undefined";
}

- (UMConfigObject *)initWithConfig:(NSDictionary *)o
{
    self = [super init];
    if(self)
    {
        _subEntries =     [[NSMutableArray<UMConfigObject *> alloc] init];
        [self setSuperConfig:o];
    }
    return self;
}

- (NSString *)configString
{
    NSMutableString *s = [[NSMutableString alloc]init];
    [self appendConfigToString:s];
    return s;
}

- (void)appendConfigToString:(NSMutableString *)o
{
    return [self appendConfigToString:o withoutName:NO];
}

- (void)appendConfigToString:(NSMutableString *)o withoutName:(BOOL)withoutName
{
    [o appendFormat:@"\n"];

    ulib_config_appendConfig_STRING(o,"group", self.groupName,"group",1,"index");
    if(withoutName==NO)
    {
        ulib_config_appendConfig_STRING(o,"name",_name,"name",2,"index,unique");
    }
    ulib_config_appendConfig_STRING(o,"description",_objectDescription,"description",3,"");
    ulib_config_appendConfig_BOOLEAN(o,"enable",_enabled,"enable",4,"");
    ulib_config_appendConfig_INTEGER(o,"log-level",_logLevel,"log_level",5,"");
    ulib_config_appendConfig_STRING(o,"log-file",_logFile,"log_file",6,"");
    ulib_config_appendConfig_ARRAY_VERBOSE(o,"comment",_comments,"comment",7,"");
}

- (UMSynchronizedSortedDictionary *)config
{
    return [self configWithoutName:NO];
}

- (UMSynchronizedSortedDictionary *)configWithoutName:(BOOL)withoutName
{
    UMSynchronizedSortedDictionary *o = [[UMSynchronizedSortedDictionary alloc]init];
    
    
#include "UMConfig_macroAppendDict.h"

    ulib_config_appendDict_STRING(o,"group", self.groupName,"group",1,"index");
    if((withoutName==NO) && (_name.length >0))
    {
        ulib_config_appendDict_STRING(o,"name",_name,"name",2,"index,unique");
    }
    ULIBCONFIG_STRING(o,"description",_objectDescription,"description",3,"");
    ULIBCONFIG_BOOLEAN(o,"enable",_enabled,"enable",4,"");
    ULIBCONFIG_INTEGER(o,"log-level",_logLevel,"log_level",5,"");
    ULIBCONFIG_STRING(o,"log-file",_logFile,"log_file",6,"");
    ULIBCONFIG_ARRAY_VERBOSE(o,"comment",_comments,"comment",7,"");
#include "UMConfig_macroClear.h"

    return o;
}

- (NSArray *)subConfig
{
    NSMutableArray *array = [[NSMutableArray alloc]init];
    for(UMConfigObject *e in _subEntries)
    {
        [array addObject:e.config];
    }
    return array;
}

- (void)setConfig:(NSDictionary *)o
{
    /* to be defined in subclass */
}

- (void)setSubConfig:(NSArray *)configs
{
    /* to be defined in subclass */
}

- (void)setSuperConfig:(NSDictionary *)o
{
    /* group can not be set as the subclass defines it statically.
     So we already have to be the right object */

    /* names can only be filtered names */
    NSString *group =  o[@"group"];
    id n = o[@"name"];
    if((n==NULL) && (self.requiresName))
    {
        NSString *s = [NSString stringWithFormat:@"Error: object of type %@ without a name",group];
        @throw([NSException exceptionWithName:@"CONFIG"
                                       reason:NULL
                                     userInfo:@{
                                                @"sysmsg" : s,
                                                @"func": @(__func__),
                                                @"obj" : self,
                                                @"backtrace": UMBacktrace(NULL,0)
        }]);
    }
    else if([n isKindOfClass:[NSString class]])
    {
        NSString *n2 = [UMConfigObject filterName:(NSString *)n];
        if(n2.length > 0)
        {
            _name = n2;
        }
    }
    else
    {
        NSLog(@"Warning: Not a string for an object name. Probably misconfiguration: %@ in group %@",n,group);
    }

    NSString *newName = [UMConfigObject filterName:o[@"newname"]];
    if((newName.length > 0) && (![newName isEqualToString:_name]))
    {
        _oldName = _name;
        _name = newName;
        _nameChanged = YES;
    }
    
#include "UMConfig_macroSetConfigFromDict.h"
    ULIBCONFIG_STRING(o,"description",_objectDescription,"description",3,"");
    ULIBCONFIG_BOOLEAN(o,"enable",_enabled,"enable",4,"");
    ULIBCONFIG_INTEGER(o,"log-level",_logLevel,"log_level",5,"");
    ULIBCONFIG_STRING(o,"log-file",_logFile,"log_file",6,"");
#include "UMConfig_macroClear.h"

    id comments = o[@"comment"];
    if([comments isKindOfClass:[NSArray class]])
    {
        _comments = (NSArray *)comments;
    }
    else if([comments isKindOfClass:[NSString class]])
    {
        _comments = [((NSString *)comments) componentsSeparatedByString:@"\n"];
    }
}

+(NSString *)filterName:(NSString *)str
{
    if(str==NULL)
    {
        return NULL;
    }
    NSInteger LIMIT = 64;
    char out[LIMIT];
    NSInteger i;
    NSInteger j=0;
    NSInteger n=str.length;
    if(n>LIMIT)
    {
        n = LIMIT;
    }
    memset(out,0x00,sizeof(out));
    for(i=0;i<n;i++)
    {
        unichar c = [str characterAtIndex:i];
        if((c>='a') && (c<='z'))
        {
            out[j++]=c;
        }
        else if((c>='A') && (c<='Z'))
        {
            out[j++]=c;
        }
        else if((c>='0') && (c<='9'))
        {
            out[j++]=c;
        }
        else
        {
            switch(c)
            {
                case '.':
                    if(i>0)
                    {
                        out[j++]=c;
                    }
                    break;
                case '_':
                case '-':
                case '+':
                case ',':
                case '=':
                case '%':
                    out[j++]=c;
                    break;
                default:
                    break;
            }
        }
    }
    out[LIMIT-1]='\0';
    NSString *result = @(out);
    if(![str isEqualToString:result])
    {
        NSLog(@"** WARNING *** Name has been filtered from '%@' to '%@'",str,result);
    }
    return result;
}

- (UMConfigObject *)copyWithZone:(NSZone *)zone
{
    UMSynchronizedSortedDictionary *currentConfig = [self config];
    UMConfigObject *o = [[UMConfigObject allocWithZone:zone]initWithConfig:[currentConfig dictionaryCopy]];
    o.subEntries = _subEntries;
    return o;
}

- (void)addSubEntry:(UMConfigObject *)obj
{
    if(_subEntries==NULL)
    {
       _subEntries =  [[NSMutableArray alloc]init];
    }
    [_subEntries addObject:obj];
}

- (NSArray<NSDictionary *> *)subConfigs
{
    NSMutableArray *configs = [[NSMutableArray alloc]init];
    for(UMConfigObject *co in _subEntries)
    {
        [configs addObject:[co.config dictionaryCopy]];
    }
    return configs;
}

- (id)proxyForJson
{
    return self.config;
}

- (UMConfigObject *)initWithString:(NSString *)s
{
    NSArray *lines = [s componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    for(NSString *line in lines)
    {
        NSArray *items  = [line componentsSeparatedByString:@"="];
        if ([items count] == 2)
        {
            NSString *tag = [[items objectAtIndex:0] trim];
            NSString *val = [[items objectAtIndex:1] trim];
            dict[tag] = val;
        }
    }
    return [self initWithConfig:dict];
}

- (NSString *)description
{
    NSMutableString *s = [[NSMutableString alloc]init];
    [s appendString:[super description]];
    [s appendString:@"\n{"];
    [s appendString:[self configString]];
    [s appendString:@"\n}"];
    return s;
}

- (BOOL)requiresName
{
    return NO;
}

@end
