//
//  UMConfig_macroSetConfigFromDict.h
//  ulib
//
//  Created by Andreas Fink on 26.11.2026.
//

#define ULIBCONFIG_BOOLEAN(o,name,value,dbname,tag,options)            { NSNumber *v = ulib_config_setConfigFromDict_BOOLEAN(o,name,dbname,tag,options);         if(v) { value=v;}}
#define ULIBCONFIG_REAL(o,name,value,dbname,tag,options)               { NSNumber *v = ulib_config_setConfigFromDict_REAL(o,name,dbname,tag,options);            if(v) { value=v;}}
#define ULIBCONFIG_INTEGER(o,name,value,dbname,tag,options)            { NSNumber *v = ulib_config_setConfigFromDict_INTEGER(o,name,dbname,tag,options);         if(v) { value=v;}}
#define ULIBCONFIG_STRING(o,name,value,dbname,tag,options)             { NSString *v = ulib_config_setConfigFromDict_STRING(o,name,dbname,tag,options);          if(v) { value=v;}}
#define ULIBCONFIG_FILTERED_STRING(o,name,value,dbname,tag,options)    { NSString *v = ulib_config_setConfigFromDict_FILTERED_STRING(o,name,dbname,tag,options); if(v) { value=v;}}
#define ULIBCONFIG_DATE(o,name,value,dbname,tag,options)               { NSDate   *v = ulib_config_setConfigFromDict_DATE(o,name,dbname,tag,options);            if(v) { value=v;}}
#define ULIBCONFIG_ARRAY_COMPACT(o,name,value,dbname,tag,options)      { NSArray  *v = ulib_config_setConfigFromDict_ARRAY_COMPACT(o,name,dbname,tag,options);   if(v) { value=v;}}
#define ULIBCONFIG_ARRAY_VERBOSE(o,name,value,dbname,tag,options)      { NSArray  *v = ulib_config_setConfigFromDict_ARRAY_VERBOSE(o,name,dbname,tag,options);   if(v) { value=v;}}
#define ULIBCONFIG_HEXDATA(o,name,value,dbname,tag,options)            { NSData   *v = ulib_config_setConfigFromDict_HEXDATA(o,name,dbname,tag,options);         if(v) { value=v;}}

