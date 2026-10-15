//
//  UMWebObject.m
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import "UMWebObject.h"


@implementation UMWebObject


- (UMWebObject *)initWithString:(NSString *)s tag:(NSString *)t children:(NSArray *)c
{
    self = [super init];
    if(self)
    {
        if(s)
        {
            _content = s;
        }
        if(c)
        {
            self.children = c;
        }
        if(t)
        {
            self.tag = t;
        }
    }
    return self;
}

- (UMWebObject *)initWithString:(NSString *)s
{
    return [self initWithString:s tag:NULL children:NULL];
}


- (UMWebObject *)initWithString:(NSString *)text children:(NSArray *)children
{
    return [self initWithString:text tag:NULL children:children];
}

- (UMWebObject *)initWithChildren:(NSArray *)children
{
    return [self initWithString:NULL tag:NULL children:children];
}

- (void)addChild:(id<UMWebObjectProtocol>)c
{
    if(_children==NULL)
    {
        _children =[[UMSynchronizedArray alloc]init];
    }
    [_children addObject:c];
}

+ (NSString *)identOfSize:(int)size
{
    NSMutableString *s = [[NSMutableString alloc]init];
    while(size-- > 0)
    {
        [s appendString:@" "];
    }
    return s;
}

- (NSString *)htmlString:(BOOL)humanReadable ident:(int)ident flags:(UMWebObjectFlags)flags
{
    NSString *identString = [UMWebObject identOfSize:ident];
    NSMutableString *s = [[NSMutableString alloc]init];
    BOOL doIdent = humanReadable;
    BOOL doNL;
    
    if(flags & UMWebObjectFlag_PRE)
    {
        doIdent=NO;
        doNL=NO;
    }
    else
    {
        if(humanReadable)
        {
            doNL=YES;
        }
        else
        {
            doNL=NO;
        }
    }
    
    if(_tag)
    {
        if(doIdent)
        {
            [s appendString:identString];
        }
        [s appendString:@"<"];
        [s appendString:_tag];
        if(_attributes)
        {
            NSArray<NSString *> *keys = [_attributes allKeys];
            for(NSString *key in keys)
            {
                NSString *value = _attributes[key];
                [s appendFormat:@" %@",key];
                if(![value isKindOfClass:[NSNull class]])
                {
                    [s appendFormat:@"=%@",value];
                }
            }
        }
        [s appendString:@">"];
        if((doNL) && (_noWrap==NO))
        {
            [s appendString:@"\n"];
        }
    }
    if(_children)
    {
        BOOL preFlagSet = NO;
        BOOL hasPreFlag = (flags & UMWebObjectFlag_PRE);
        if(([_tag isEqualToString:@"PRE"]) && !hasPreFlag)
        {
            preFlagSet=YES;
            flags = flags | UMWebObjectFlag_PRE;
        }
        for(id<UMWebObjectProtocol> child in _children)
        {
            NSString *childString = [child htmlString:humanReadable ident:ident+4 flags:flags];
            [s appendString:childString];
        }
        if(preFlagSet)
        {
            flags = flags & ~UMWebObjectFlag_PRE;
        }
    }
    if(_content)
    {
        if((doIdent) && (_noWrap==NO))
        {
            NSString *identString2 = [UMWebObject identOfSize:ident+4];
            [s appendString:identString2];
        }
        [s appendString:_content];
        if((doNL)&& (_noWrap==NO))
        {
            [s appendString:@"\n"];
        }

    }
    if(_tag)
    {
        if((doIdent) && (_noWrap==NO))
        {
            [s appendString:identString];
        }
        [s appendString:@"</"];
        [s appendString:_tag];
        [s appendString:@">"];
        if(doNL)
        {
            [s appendString:@"\n"];
        }
    }
    return s;
}

- (void)setTag:(NSString *)tag
{
    _tag = [tag uppercaseString];
}

- (NSString *)tag
{
    return _tag;
}


- (NSArray *)children
{
    return _children.arrayCopy;
}

- (void)setChildren:(NSArray *)a
{
    _children = [[UMSynchronizedArray alloc]initWithArray:a];
}


@end

