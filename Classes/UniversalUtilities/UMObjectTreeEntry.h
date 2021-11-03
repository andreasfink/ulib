//
//  UMObjectTreeEntry.h
//  ulib
//
//  Created by Andreas Fink on 03.11.21.
//  Copyright © 2021 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>
#import "UMSynchronizedDictionary.h"

@interface UMObjectTreeEntry : UMObject

{
    UMSynchronizedDictionary *_subEntries;
    id _payload;
}

- (id)getEntry:(NSString *)key;
- (id)getPayload;

- (void)setEntry:(id)obj forKey:(NSString *)key;
- (void)setPayload:(id)obj;

@end


