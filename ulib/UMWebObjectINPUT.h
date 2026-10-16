//
//  UMWebObjectINPUT.h
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import <ulib/UMWebObject.h>



@interface UMWebObjectINPUT : UMWebObject
{
    NSString *_name;
}

- (UMWebObjectINPUT *)initTypeTextWithName:(NSString *)name;

@end


