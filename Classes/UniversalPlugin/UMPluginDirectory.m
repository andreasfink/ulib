//
//  UMPluginDirectory.m
//  ulib
//
//  Created by Andreas Fink on 23.04.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMPluginDirectory.h"
#import "UMPluginHandler.h"

@implementation UMPluginDirectory

- (UMPluginDirectory *)init
{
    self = [super init];
    if(self)
    {
        _entries = [[UMSynchronizedSortedDictionary alloc]init];
    }
    return self;
}

- (void)scanForPlugins:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = NULL;

    NSArray *entries = [fileManager contentsOfDirectoryAtPath:path error:&error];
    for (NSString *entry in entries)
    {
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@",path,entry];
        UMPluginHandler *handler = [[UMPluginHandler alloc]initWithFile:fullPath];
        if([handler open] ==0)
        {
            _entries[handler.name] = handler;
        }
    }
}

- (NSDictionary *) entries
{
    return [_entries mutableCopy];
}



@end
