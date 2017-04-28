//
//  UMPlugin.h
//  ulib
//
//  Created by Andreas Fink on 21.04.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"
#import "UMSynchronizedSortedDictionary.h"

@interface UMPlugin : UMObject
{
    NSArray *_config; /* textual representation */
}

+ (NSDictionary *)info;
+ (NSString *)name;
- (NSArray *)config;
- (void)setConfig:(NSArray *)cfg;
- (void)configUpdate;

@end

/* an actual plugin should implement these methods too:

int         plugin_init(void); // [optional] load routine initialize globals etc
int         plugin_exit(void); // [optional]unload routine
NSString *  plugin_name(void);  // [optional] return name of plugin defaults to info["@name"]
UMPlugin *  plugin_create(void);    // [mandatory] return plugin object
NSDictionary * plugin_info(void);   // [mandatory] return attributes dictionary

*/
