//
//  UMCommandActionProtocol.h
//  ulib
//
//  Created by Andreas Fink on 26.02.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import "UMObject.h"

@class UMSyntaxContext;

@protocol UMCommandActionProtocol<NSObject>

- (void)commandPreAction:(NSString *)actionName value:(NSString *)value context:(UMSyntaxContext *)context;
- (void)commandAction:(NSString *)actionName value:(NSString *)value context:(UMSyntaxContext *)context;
- (void)commandPostAction:(NSString *)actionName value:(NSString *)value context:(UMSyntaxContext *)context;

@end
