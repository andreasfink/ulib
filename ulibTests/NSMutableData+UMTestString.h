//
//  NSMutableData+UMTestString.h
//  ulib
//
//  Created by Aarno Syvänen on 11.10.12.
//
//

#import <Foundation/Foundation.h>

@interface NSMutableData (UMTestString)

- (void)binaryToBase64;
- (void)stripBlanks;
- (BOOL)blankAtBeginning:(int)start;
- (BOOL)blankAtEnd:(int)end;


@end
