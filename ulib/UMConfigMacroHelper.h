//
//  UMConfigMacroHelper.h
//  ulib
//
//  Created by Andreas Fink on 26.11.2026.
//

#ifndef UMConfigMacroHelper_h
#define UMConfigMacroHelper_h


#endif /* UMConfigMacroHelper_h */
//
//  UMSS7ConfigMacroHelper.h
//  estp
//
//  Created by Andreas Fink on 08.03.18.
//  Copyright © 2018 Andreas Fink. All rights reserved.
//
#import <ulib/ulib.h>

void ulib_config_appendConfig_BOOLEAN(NSMutableString *str,const char *name,NSNumber *value,const char *dbname,int tag,const char *options);
void ulib_config_appendConfig_REAL(NSMutableString *str,const char *name,NSNumber *value,const char *dbname,int tag,const char *options);
void ulib_config_appendConfig_INTEGER(NSMutableString *str,const char *name,NSNumber *value,const char *dbname,int tag,const char *options);
void ulib_config_appendConfig_STRING(NSMutableString *str,const char *name,NSString *value,const char *dbname,int tag,const char *options);
void ulib_config_appendConfig_HEXDATA(NSMutableString *str,const char *name,NSData *value,const char *dbname,int tag,const char *options);
void ulib_config_appendConfig_FILTERED_STRING(NSMutableString *str,const char *name,NSString *value,const char *dbname,int tag,const char *options);
void ulib_config_appendConfig_DATE(NSMutableString *str,const char *name,NSDate *value,const char *dbname,int tag,const char *options);
void ulib_config_appendConfig_ARRAY_VERBOSE(NSMutableString *str,const char *name,NSArray *array,const char *dbname,int tag,const char *options);
void ulib_config_appendConfig_ARRAY_COMPACT(NSMutableString *str,const char *name,NSArray *array,const char *dbname,int tag,const char *options);

void ulib_config_appendDict_BOOLEAN(UMSynchronizedSortedDictionary *dict,const char *name,NSNumber *value,const char *dbname,int tag,const char *options);
void ulib_config_appendDict_REAL(UMSynchronizedSortedDictionary *dict,const char *name,NSNumber *value,const char *dbname,int tag,const char *options);
void ulib_config_appendDict_INTEGER(UMSynchronizedSortedDictionary *dict,const char *name,NSNumber *value,const char *dbname,int tag,const char *options);
void ulib_config_appendDict_STRING(UMSynchronizedSortedDictionary *dict,const char *name,NSString *value,const char *dbname,int tag,const char *options);
void ulib_config_appendDict_HEXDATA(UMSynchronizedSortedDictionary *dict,const char *name,NSData *value,const char *dbname,int tag,const char *options);
void ulib_config_appendDict_FILTERED_STRING(UMSynchronizedSortedDictionary *dict,const char *name,NSString *value,const char *dbname,int tag,const char *options);
void ulib_config_appendDict_DATE(UMSynchronizedSortedDictionary *dict,const char *name,NSDate *value,const char *dbname,int tag,const char *options);
void ulib_config_appendDict_ARRAY_VERBOSE(UMSynchronizedSortedDictionary *dict,const char *name,NSArray *array,const char *dbname,int tag,const char *options);
void ulib_config_appendDict_ARRAY_COMPACT(UMSynchronizedSortedDictionary *dict,const char *name,NSArray *array,const char *dbname,int tag,const char *options);

NSNumber * ulib_config_setConfigFromDict_BOOLEAN(NSDictionary *o,const char *name,const char *dbname,int tag,const char *options);
NSNumber * ulib_config_setConfigFromDict_REAL(NSDictionary *o,const char *name,const char *dbname,int tag,const char *options);
NSNumber * ulib_config_setConfigFromDict_INTEGER(NSDictionary *o,const char *name,const char *dbname,int tag,const char *options);
NSString * ulib_config_setConfigFromDict_STRING(NSDictionary *o,const char *name,const char *dbname,int tag,const char *options);
NSData   * ulib_config_setConfigFromDict_HEXDATA(NSDictionary *o,const char *name,const char *dbname,int tag,const char *options);
NSString * ulib_config_setConfigFromDict_FILTERED_STRING(NSDictionary *o,const char *name,const char *dbname,int tag,const char *options);
NSDate   * ulib_config_setConfigFromDict_DATE(NSDictionary *o,const char *name,const char *dbname,int tag,const char *options);
NSArray  * ulib_config_setConfigFromDict_ARRAY_COMPACT(NSDictionary *o,const char *name,const char *dbname,int tag,const char *options);
NSArray  * ulib_config_setConfigFromDict_ARRAY_VERBOSE(NSDictionary *o,const char *name,const char *dbname,int tag,const char *options);
