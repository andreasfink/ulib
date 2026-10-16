//
//  UMWebObjectA.h
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import <ulib/UMWebObject.h>


@interface UMWebObjectA : UMWebObject
{
    NSString *_href;
}

@property(readwrite,strong) NSString *href;

- (UMWebObjectA *)initWithURL:(NSString *)url text:(NSString *)text;

@end

