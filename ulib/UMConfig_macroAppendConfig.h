//
//  UMConfig_macroAppendConfig.h
//  ulib
//
//  Created by Andreas Fink on 26.11.2026.
//

#define ULIBCONFIG_BOOLEAN(str,name,value,dbname,tag,options)          ulib_config_appendConfig_BOOLEAN(str,name,value,dbname,tag,options);
#define ULIBCONFIG_REAL(str,name,value,dbname,tag,options)             ulib_config_appendConfig_REAL(str,name,value,dbname,tag,options);
#define ULIBCONFIG_INTEGER(str,name,value,dbname,tag,options)          ulib_config_appendConfig_INTEGER(str,name,value,dbname,tag,options);
#define ULIBCONFIG_STRING(str,name,value,dbname,tag,options)           ulib_config_appendConfig_STRING(str,name,value,dbname,tag,options);
#define ULIBCONFIG_FILTERED_STRING(str,name,value,dbname,tag,options)  ulib_config_appendConfig_FILTERED_STRING(str,name,value,dbname,tag,options);
#define ULIBCONFIG_DATE(str,name,value,dbname,tag,options)             ulib_config_appendConfig_DATE(str,name,value,dbname,tag,options);
#define ULIBCONFIG_ARRAY_VERBOSE(str,name,value,dbname,tag,options)    ulib_config_appendConfig_ARRAY_VERBOSE(str,name,value,dbname,tag,options);
#define ULIBCONFIG_ARRAY_COMPACT(o,name,value,dbname,tag,options)      ulib_config_appendConfig_ARRAY_COMPACT(str,name,value,dbname,tag,options);
#define ULIBCONFIG_HEXDATA(str,name,value,dbname,tag,options)          ulib_config_appendConfig_HEXDATA(str,name,value,dbname,tag,options);

