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

@class UMWebObjectHTML;

@interface UMWebObject : UMObject
{
    UMSynchronizedArray             *_children;
    NSString                        *_tag;
    UMSynchronizedSortedDictionary  *_attributes;
    BOOL                            _noWrap; /* if set, out put is <text>text</tag> instead of <tag>\ntext\n</tag> */
    __weak UMWebObject              *_parentObject;
    __weak UMWebObject              *_rootObject;
    BOOL                            _noEndTag;
}


@property(readwrite,strong) NSArray                         *children;
@property(readwrite,strong) NSString                        *tag;
@property(readwrite,strong) UMSynchronizedSortedDictionary  *attributes;
@property(readwrite,assign) BOOL                            noWrap;
@property(readwrite,assign) BOOL                            noEndTag;
@property(readwrite,weak) UMWebObject                       *parentObject;
@property(readwrite,weak) UMWebObject                       *rootObject;

- (UMWebObject *)initWithString:(NSString *)s tag:(NSString *)t children:(NSArray *)c;
- (UMWebObject *)initWithString:(NSString *)s;
- (UMWebObject *)initWithString:(NSString *)text children:(NSArray *)children;
- (UMWebObject *)initWithChildren:(NSArray *)children;

- (NSString *)htmlString:(BOOL)humanReadable ident:(int)ident flags:(UMWebObjectFlags)flags;
- (void)addChild:(UMWebObject *)c;
- (NSArray *)allowedAttributes;
+ (NSArray *)globalAttributes;
- (void)setAttributeWithoutValue:(NSString *)attribute;
- (void)setAttribute:(NSString *) attribute value:(NSString *)value;
- (void)clearAttribute:(NSString *)attribute;

- (void)prepareAttributes; /* prepare attributes from custom fields */
- (void)postprocessAttributes; /* set custom fields from attributes */


- (UMWebObject *)initWithWebObject:(UMWebObject *)obj;
- (UMWebObject *)parse:(UMWebObject *)object; /* converts from a generic webobject to a specific web object */

- (NSString *)getAllText;
- (void)addText:(NSString *)c;
+ (NSString *)identOfLevel:(int)size;

+ (void)appendLineEndingToMutableString:(NSMutableString *)s;
+ (void)appendLineEndingToMutableString:(NSMutableString *)s line:(long)lineno tag:(NSString *)tag;
+ (UMWebObjectHTML *)webDocumentWithTitle:(NSString *)t
                                      css:(NSString *)css
                                  charset:(NSString *)charset;


@end

