//
//  NSDictionary+UniversalConfig.h
//  ulib
//
//  Created by Andreas Fink on 07.02.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSDictionary (UniversalConfig)

- (BOOL)configEnabledWithYesDefault;
- (NSString *)configName;
- (NSString *)configEntry:(NSString *)index;

@end
