//
//  UMWebObjectA.m
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import "UMWebObjectA.h"

@implementation UMWebObjectA

- (UMWebObjectA *)init
{
    self = [super init];
    if(self)
    {
        self.tag = @"a";
        _noWrap = YES;
    }
    return self;
}

- (UMWebObjectA *)initWithURL:(NSString *)url text:(NSString *)text;
{
    self = [self init];
    if(self)
    {
        _href = url;
        [self addText:text];
    }
    return self;
}

- (NSArray *)allowedAttributes
{
    static NSMutableArray *a;
    if(a)
    {
        return a;
    }
    a = [[UMWebObject globalAttributes] mutableCopy];
    [a addObject:@"charset"];   // Obsolete Specifies the character encoding of the linked resource.
    [a addObject:@"coords"];    // x,y coordinates Obsolete Specifies the position of the link on the screen.
    [a addObject:@"download"];  // filename Specifies whether to download the linked resource instead of navigating to it, when the user clicks on the link.
    
    [a addObject:@"href"];      // URL Specifies the location of the destination document or web resource (such as an image, PDF, or other media file).
    [a addObject:@"hreflang"];  // language-code Specifies the language of the linked document. This attribute may only be used when href is specified.
    [a addObject:@"media"];     // media-query Specifies the media for which the linked resource is designed.
    [a addObject:@"name"];      // text Obsolete Specifies the name of an anchor. Use the global attribute id instead.
    [a addObject:@"rel"];       /* alternate, author, bookmark, help, license, next, nofollow, noreferrer,
                   prefetch, prev, search */
    [a addObject:@"tag"];       // Describes the relationship between the document containing the hyperlink and the linked resource. This attribute should be used only if the href attribute is present. */
    [a addObject:@"rev"];       // link-type Obsolete Describes the relationship of the linked document back to the source document (the opposite of the rel attribute).
    [a addObject:@"shape"];     // rect,circle", poly, default    Obsolete Specifies the shape of the hotspot region i.e., selectable region for hyperlinks.
    [a addObject:@"target"];    // _blank,_parent,_self,_top
    [a addObject:@"framename"]; // Defines a target to open the linked resource specified in the href attribute.
    [a addObject:@"type"];      // content-type
    return a;
}

- (void)prepareAttributes
{
    if(_href.length > 0)
    {
        [self setAttribute:@"href" value:_href];
    }
}

- (void)postprocessAttributes
{
    _href = _attributes[@"href"];
}

@end
