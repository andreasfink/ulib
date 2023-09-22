//
//  NSDictionary+ulib.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSDictionary(ulib)

- (NSString *)hierarchicalDescriptionWithPrefix:(NSString *)prefix; /*!< convert a NSDictionary to a string in a human readable fashion with identation (prefix) being properly handled */
- (NSDictionary *)urldecodeStringValues;
- (NSString *)logDescription;
- (NSMutableArray *) toArray;
- (NSString *)jsonString;
- (NSString *)jsonCompactString;
- (BOOL)configEnabledWithYesDefault;
- (NSString *)configName;
- (NSString *)configEntry:(NSString *)index;

/* takes every string in the dictionary and does urldecode it */
@end
