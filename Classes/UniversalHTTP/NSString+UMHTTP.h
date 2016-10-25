//
//  NSString+HTTP.h
//  ulib
//
//  Created by Andreas Fink on 30.08.11.
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (UMHTTP)

- (NSArray *)splitByFirstCharacter:(unichar)uc;
- (NSString *)urldecode;
- (NSData *)urldecodeData;

@end
