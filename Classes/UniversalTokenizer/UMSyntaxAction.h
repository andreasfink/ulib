//
//  UMSyntaxAction.h
//  ulib
//
//  Created by Andreas Fink on 26.02.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import "UMObject.h"

@class UMSyntaxContext;

@interface UMSyntaxAction : UMObject
{
}

- (void)executeWithContext:(UMSyntaxContext *)context;

@end
