//
//  NSString+HTTP.h
//  ulib
//
//  Created by Andreas Fink on 30.08.11.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (UMHTTP)

- (NSArray *)splitByFirstCharacter:(unichar)uc;
- (NSString *)urldecode;
- (NSData *)urldecodeData;
- (NSString *) urlencode;
- (NSData *)decodeBase64;
@end
