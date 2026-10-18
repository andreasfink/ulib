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
    UMWebObjectFlag_LINE_ENDING_DEBUG = 2,
    UMWebObjectFlag_IDENT_DEBUG = 4,
} UMWebObjectFlags;

/*
@protocol UMWebObjectProtocol<NSObject>

- (NSString *)htmlString:(BOOL)humanReadable ident:(int)ident flags:(UMWebObjectFlags)flags;


@end

*/
