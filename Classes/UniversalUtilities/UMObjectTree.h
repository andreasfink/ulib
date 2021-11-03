//
//  UMObjectTree.h
//  ulib
//
//  Created by Andreas Fink on 03.11.21.
//  Copyright © 2021 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UMObject.h"
#import "UMMutex.h"

@class UMObjectTreeEntry;

@interface UMObjectTree : UMObject
{
    UMMutex          *_lock;
    UMObjectTreeEntry *_root;
}

- (void)addEntry:(id)obj  forKeys:(NSArray<NSString *>*)keys;
- (id)getEntryForKeys:(NSArray<NSString *>*)keys;

@end
