//
//  UMWebObjectSELECT.h
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import <ulib/UMWebObject.h>



@interface UMWebObjectSELECT : UMWebObject

- (void)select:(NSString *)value;

- (void)addOptionWithValue:(NSString *)value text:(NSString *)text;

@end


