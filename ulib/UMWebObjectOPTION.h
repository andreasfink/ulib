//
//  UMWebObjectOPTION.h
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import <ulib/UMWebObject.h>



@interface UMWebObjectOPTION : UMWebObject
{
    NSString    *_value;
    BOOL        _isDefault;
}

- (UMWebObjectOPTION *)initWithValue:(NSString *)value text:(NSString *)text;

@property(readwrite,strong) NSString    *value;
@property(readwrite,assign) BOOL        isDefault;

@end


