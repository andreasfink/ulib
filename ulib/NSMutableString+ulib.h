//
//  NSMutableString+ulib.h
//  ulib
//
//  Created by Andreas Fink on 23.10.12.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/framework.h>


@interface NSMutableString (ulib)

- (void)stripBlanks;
- (void)binaryToBase64;

@end
