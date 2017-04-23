//
//  UMPluginDirectory.h
//  ulib
//
//  Created by Andreas Fink on 23.04.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>

@interface UMPluginDirectory : UMObject
{
    UMSynchronizedSortedDictionary *_entries;
}

- (void)scanForPlugins:(NSString *)directory;
- (NSDictionary *) entries;


@end
