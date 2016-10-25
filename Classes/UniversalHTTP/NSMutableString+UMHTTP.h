//
//  NSMutableString+UMHTTP.h
//  ulib
//
//  Created by Andreas Fink on 23.10.12.
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSMutableString (HTTP)

- (void)stripBlanks;
- (void)binaryToBase64;

@end
