//
//  UMPluginHandler.h
//  ulib
//
//  Created by Andreas Fink on 21.04.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"

@class UMSynchronizedArray;
@class UMPlugin;

@interface UMPluginHandler : UMObject
{
    NSString *_filename;
    void *_dlhandle;
    NSString *_error;
    NSString *_name;
    NSDictionary *_info;

    NSUInteger _instanceCount;
    UMSynchronizedArray *instances;

    int (* plugin_init_func)(void);
    int (* plugin_exit_func)(void);
    UMPlugin * (* plugin_create_func)(void);
    NSString * (* plugin_name_func)(void);
    NSDictionary * (* plugin_info_func)(void);
}

@property(readwrite,strong,atomic)  NSString *filename;
@property(readwrite,strong,atomic)  NSString *name;
@property(readwrite,strong,atomic)  NSDictionary *info;


- (UMPluginHandler *)initWithFile:(NSString *)filename;
- (int)open;
- (int)close;
- (UMPlugin *)instantiate;
- (void)destroy:(UMPlugin *)plugin;

@end
