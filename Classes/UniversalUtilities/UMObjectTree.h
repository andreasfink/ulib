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
    UMMutex          *_objectTreeLock;
    UMObjectTreeEntry *_root;
}

- (void)addEntry:(id)obj  forKeys:(NSArray<NSString *>*)keys;
- (id)getEntryForKeys:(NSArray<NSString *>*)keys;
- (id)getEntryForKeysReversed:(NSArray<NSString *>*)keys;
- (NSArray *)getCumulativeEntryForKeys:(NSArray<NSString *>*)keys;
- (NSArray *)getCumulativeEntryForKeysReversed:(NSArray<NSString *>*)keys;

@end
