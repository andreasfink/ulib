//
//  UMWebObjectProtocol.h
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import <ulib/UMObject.h>

typedef enum UMWebObjectFlags
{
    UMWebObjectFlag_PRE = 1,
} UMWebObjectFlags;


@protocol UMWebObjectProtocol<NSObject>

- (NSString *)htmlString:(BOOL)humanReadable ident:(int)ident flags:(UMWebObjectFlags)flags;


@end

