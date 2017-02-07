//
//  NSDictionary+UniversalConfig.h
//  ulib
//
//  Created by Andreas Fink on 07.02.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import <foundation/foundation.h>


@interface NSDictionary (UniversalConfig)

- (BOOL)configEnabledWithYesDefault;
- (NSString *)configName;
- (NSString *)configEntry:(NSString *)index;

@end
