//
//  NSDictionary+UMHTTP.h
//  ulib
//
//  Created by Andreas Fink on 23.10.12.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#ifndef NSDictionary_UMHTTP_h
#define NSDictionary_UMHTTP_h 1

#import <Foundation/Foundation.h>

@interface NSDictionary (UMHTTP)

- (NSString *)logDescription;
- (NSMutableArray *) toArray;

@end

#endif

