//
//  UMWebObjectPlaintext.h
//  ulib
//
//  Created by Andreas Fink on 16.10.2026.
//

#import <ulib/ulib.h>

@interface UMWebObjectPlaintext : UMWebObject
{
    NSString *_text;
}

@property(readwrite,strong) NSString *text;

@end

