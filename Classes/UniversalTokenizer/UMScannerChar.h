//
//  UMScannerChar.h
//  ulib
//
//  Created by Andreas Fink on 26.02.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import "UMObject.h"

@interface UMScannerChar : UMObject
{
    unichar _character;
    NSInteger _line;
    NSInteger _colum;
    NSString *_sourceFile;
}

@property(readwrite,assign,atomic)  unichar character;
@property(readwrite,assign,atomic)  NSInteger line;
@property(readwrite,assign,atomic)  NSInteger colum;
@property(readwrite,strong,atomic)  NSString *sourceFile;

@end
