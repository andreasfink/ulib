//
//  UMDigitTreeEntry.h
//  ulib
//
//  Created by Andreas Fink on 25.05.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/framework.h>

@interface UMDigitTreeEntry : NSObject
{
    id _subEntries[16];
    id _payload;
}

- (id)getEntry:(int)index;
- (id)getPayload;

- (void)setEntry:(id)obj forIndex:(int)index;
- (void)setPayload:(id)obj;

@end
