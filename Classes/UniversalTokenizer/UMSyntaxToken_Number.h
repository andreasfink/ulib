//
//  UMSyntaxToken_Number.h
//  ulib
//
//  Created by Andreas Fink on 25.02.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import "UMSyntaxToken.h"

@interface UMSyntaxToken_Number : UMSyntaxToken
{
    int _min;
    int _max;
}

@property(readwrite,assign,atomic) int min;
@property(readwrite,assign,atomic) int max;

@end
