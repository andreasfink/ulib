//
//  UMDigitTree.h
//  ulib
//
//  Created by Andreas Fink on 25.05.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UMDigitTreeEntry.h"
#import "UMMutex.h"

@interface UMDigitTree : NSObject
{
    UMMutex          *_lock;
    UMDigitTreeEntry *_root;
}

- (void)addEntry:(id)obj  forDigits:(NSString *)digits;
- (id)getEntryForDigits:(NSString *)digits;

@end

