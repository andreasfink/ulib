//
//  UMPluginHandler.m
//  ulib
//
//  Created by Andreas Fink on 21.04.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMPluginHandler.h"
#import "UMSynchronizedArray.h"
#import "UMPlugin.h"

#include <dlfcn.h>

@implementation UMPluginHandler

- (UMPluginHandler *)initWithFile:(NSString *)filename
{
    self = [super init];
    if(self)
    {
        _filename = filename;
    }
    return self;
}

- (int) open
{
    _dlhandle = dlopen(_filename.UTF8String,RTLD_NOW | RTLD_LOCAL);
    if(_dlhandle == NULL)
    {
        _error = @(dlerror());
        return -1;
    }

    plugin_init_func    = dlsym(_dlhandle, "plugin_init");
    plugin_exit_func    = dlsym(_dlhandle, "plugin_exit");
    plugin_create_func  = dlsym(_dlhandle, "plugin_create");
    plugin_name_func    = dlsym(_dlhandle, "plugin_name");
    plugin_info_func    = dlsym(_dlhandle, "plugin_info");

    if(!plugin_create_func)
    {
        _error = @"plugin_create function not found";
        return -2;
    }

    if(!plugin_name_func)
    {
        _error = @"plugin_name function not found";
        return -2;
    }

    if(!plugin_info_func)
    {
        _error = @"plugin_info function not found";
        return -2;
    }

    if(plugin_init_func)
    {
        int e = (*plugin_init_func)();
        if(e)
        {
            _error = [NSString stringWithFormat:@"plugin_init() returned %d",e];
            return -3;
        }
    }
    _info = (*plugin_info_func)();
    if(plugin_name_func)
    {
        _name = (*plugin_name_func)();
    }
    else
    {
        _name = _info[@"name"];
    }
    return 0;
}

- (int) close
{
    return(*plugin_exit_func)();
}


- (UMPlugin *)instantiate
{
    _instanceCount++;
    UMPlugin *plugin = (* plugin_create_func)();

    [instances addObject:plugin];
    return plugin;
}

- (void)destroy:(UMPlugin *)plugin
{
    [instances removeObject:plugin];
    _instanceCount = [instances count];
}

@end