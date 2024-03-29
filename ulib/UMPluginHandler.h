//
//  UMPluginHandler.h
//  ulib
//
//  Created by Andreas Fink on 21.04.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMObject.h>

@class UMSynchronizedArray;
@class UMPlugin;

@interface UMPluginHandler : UMObject
{
    NSString        *_filename;
    void            *_dlhandle;
    NSString        *_error;
    NSString        *_name;
    NSDictionary    *_info;

    NSUInteger _instanceCount;
    UMSynchronizedArray *instances;

    int (* plugin_init_func)(NSDictionary *dict);
    int (* plugin_exit_func)(void);
    UMPlugin * (* plugin_create_func)(void);
    NSString * (* plugin_name_func)(void);
    NSDictionary * (* plugin_info_func)(void);
}

@property(readwrite,strong,atomic)  NSString *filename;
@property(readwrite,strong,atomic)  NSString *name;
@property(readwrite,strong,atomic)  NSDictionary *info;
@property(readwrite,strong,atomic)  NSString *error;


- (UMPluginHandler *)initWithFile:(NSString *)filename;
- (int)open;
- (int) openWithDictionary:(NSDictionary *)dict;
- (int)close;
- (NSString *)reload; /* return NULL or NSString with error */
- (UMPlugin *)instantiate;
- (void)destroy:(UMPlugin *)plugin;

@end
