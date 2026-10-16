//
//  UMWebObject.h
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import <ulib/UMObject.h>
#import <ulib/UMWebObjectProtocol.h>
#import <ulib/UMSynchronizedSortedDictionary.h>
#import <ulib/UMSynchronizedArray.h>

@interface UMWebObject : UMObject<UMWebObjectProtocol>
{
    UMSynchronizedArray             *_children;
    NSString                        *_content;
    NSString                        *_tag;
    UMSynchronizedSortedDictionary  *_attributes;
    BOOL                            _noWrap; /* if set, out put is <text>text</tag> instead of <tag>\ntext\n</tag> */
    id<UMWebObjectProtocol>          _parentObject;
    id<UMWebObjectProtocol>          _rootObject;
}

@property(readwrite,strong) NSArray                         *children;
@property(readwrite,strong) NSString                        *content;
@property(readwrite,strong) NSString                        *tag;
@property(readwrite,strong) UMSynchronizedSortedDictionary  *attributes;
@property(readwrite,assign) BOOL                            noWrap;
@property(readwrite,weak) id<UMWebObjectProtocol>         parentObject;
@property(readwrite,weak) id<UMWebObjectProtocol>         rootObject;

- (UMWebObject *)initWithString:(NSString *)s tag:(NSString *)t children:(NSArray *)c;
- (UMWebObject *)initWithString:(NSString *)s;
- (UMWebObject *)initWithString:(NSString *)text children:(NSArray *)children;
- (UMWebObject *)initWithChildren:(NSArray *)children;

- (NSString *)htmlString:(BOOL)humanReadable ident:(int)ident flags:(UMWebObjectFlags)flags;
- (void)addChild:(id<UMWebObjectProtocol>)c;
- (NSArray *)allowedAttributes;
+ (NSArray *)globalAttributes;

- (UMWebObject *)initWithWebObject:(UMWebObject *)obj;
- (UMWebObject *)parse:(UMWebObject *)object; /* converts from a generic webobject to a specific web object */

@end

