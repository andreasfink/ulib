//
//  UMScanner.h
//  ulib
//
//  Created by Andreas Fink on 26.02.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import "UMObject.h"

@interface UMScanner : UMObject


- (NSArray *)scanFile:(NSString *)filename;
- (NSArray *)scanString:(NSString *)filecontent;

@end
