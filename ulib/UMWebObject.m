//
//  UMWebObject.m
//  ulib
//
//  Created by Andreas Fink on 15.10.2026.
//

#import <ulib/UMWebObject.h>
#import <ulib/UMWebObject_all.h>


@implementation UMWebObject


- (UMWebObject *)initWithString:(NSString *)s tag:(NSString *)t children:(NSArray *)c
{
    self = [self init];
    if(self)
    {
        if(c)
        {
            self.children = c;
        }
        if(s)
        {
            [self addText:s];
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

- (void)addChild:(UMWebObject *)c
{
    if(_children==NULL)
    {
        _children =[[UMSynchronizedArray alloc]init];
    }
    [_children addObject:c];
    c.rootObject = _rootObject;
    c.parentObject = _parentObject;
}

+ (NSString *)identOfLevel:(int)level
{
    NSMutableString *s = [[NSMutableString alloc]init];
    int size = level * 4;
    while(size-- > 0)
    {
        [s appendString:@" "];
    }
    return s;
}

- (void)prepareAttributes
{
    /* overload */
}

- (void)postprocessAttributes
{
    /* overload */
}


- (NSString *)htmlString:(BOOL)humanReadable
                   ident:(int)ident
                   flags:(UMWebObjectFlags)flags
{
    [self prepareAttributes];

    NSString *identString = [UMWebObject identOfLevel:ident];
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
                    [s appendFormat:@"=\"%@\"",value];
                }
            }
        }
        [s appendString:@">"];
        if((doNL) && (_noWrap==NO))
        {
            [UMWebObject appendLineEndingToMutableString:s];
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
        BOOL previousPlaintext=NO;
        for(UMWebObject *child in _children)
        {
            BOOL isPlaintext = NO;
            BOOL isBR = NO;
            /* plaintext objects never end with \n so <br> can be added on the end of the line */
            /* hence we add it here when the previous object was a plaintext object */
            if([child isKindOfClass:[UMWebObjectPlaintext class]])
            {
                isPlaintext=YES;
            }
            if([child isKindOfClass:[UMWebObjectBR class]])
            {
                isBR=YES;
            }
            NSString *childString = [child htmlString:humanReadable ident:ident+1 flags:flags];
            if((previousPlaintext) && (humanReadable) && !isBR)
            {
                [UMWebObject appendLineEndingToMutableString:s];
            }
            [s appendString:childString];
            if(isPlaintext)
            {
                previousPlaintext=YES;
            }
            else
            {
                previousPlaintext = NO;
            }
        }
        if((previousPlaintext) && (humanReadable) && _noWrap==NO)
        {
            [UMWebObject appendLineEndingToMutableString:s];
        }
        if(preFlagSet)
        {
            flags = flags & ~UMWebObjectFlag_PRE;
        }
    }
    if(_tag)
    {
        if((doIdent) && (_noWrap==NO))
        {
            [s appendString:identString];
        }
        if(_noEndTag==NO)
        {
            [s appendString:@"</"];
            [s appendString:_tag];
            [s appendString:@">"];
        }
        if(doNL)
        {
            [UMWebObject appendLineEndingToMutableString:s];
        }
    }
    return s;
}

- (void)setTag:(NSString *)tag
{
    _tag = [tag lowercaseString];
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
    for(UMWebObject *child in _children)
    {
        child.rootObject = _rootObject;
        child.parentObject = self;
    }
}


- (NSArray *)allowedAttributes
{
    return [UMWebObject globalAttributes];
}

+ (NSArray *)globalAttributes
{
    return @[@"accesskey",
             @"class",
             @"contenteditable",
             @"data-*",
             @"dir",
             @"draggable",
             @"dropzone",
             @"hidden",
             @"id",
             @"lang",
             @"spellcheck",
             @"style",
             @"tabindex",
             @"title",
             @"translate",
             @"xml:lang",
    ];
}

- (void)setAttributeWithoutValue:(NSString *)attribute
{
    if(attribute.length>0)
    {
        if(_attributes == NULL)
        {
            _attributes = [[UMSynchronizedSortedDictionary alloc]init];
        }
        _attributes[attribute] = [NSNull null];
    }
}

- (void)setAttribute:(NSString *) attribute value:(NSString *)value
{
    if(attribute==NULL)
    {
        return;
    }
    
    if(value==NULL)
    {
        [self clearAttribute:attribute];
        return;
    }
    if(_attributes == NULL)
    {
        _attributes = [[UMSynchronizedSortedDictionary alloc]init];
    }
    _attributes[attribute] = value;
}

- (void)clearAttribute:(NSString *)attribute
{
    [_attributes removeObjectForKey:attribute];
}

- (UMWebObject *)initWithWebObject:(UMWebObject *)obj
{
    self = [super init];
    if(self)
    {
        self.children   = obj.children;
        _tag            = obj.tag;
        _attributes     = obj.attributes;
        _noWrap         = obj.noWrap;
    }
    return self;
}

- (UMWebObject *)parse:(UMWebObject *)object
{
    NSString *tag = object.tag;

    if([tag isEqualToString:@"a"])
    {
        return [[UMWebObjectA alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"abbr"])
    {
        return [[UMWebObjectABBR alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"address"])
    {
        return [[UMWebObjectADDRESS alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"area"])
    {
        return [[UMWebObjectAREA alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"article"])
    {
        return [[UMWebObjectARTICLE alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"aside"])
    {
        return [[UMWebObjectASIDE alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"audio"])
    {
        return [[UMWebObjectAUDIO alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"b"])
    {
        return [[UMWebObjectB alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"base"])
    {
        return [[UMWebObjectBASE alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"bdi"])
    {
        return [[UMWebObjectBDI alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"blockquote"])
    {
        return [[UMWebObjectBLOCKQUOTE alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"body"])
    {
        return [[UMWebObjectBODY alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"br"])
    {
        return [[UMWebObjectBR alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"button"])
    {
        return [[UMWebObjectBUTTON alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"caption"])
    {
        return [[UMWebObjectCAPTION alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"cite"])
    {
        return [[UMWebObjectCITE alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"code"])
    {
        return [[UMWebObjectCODE alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"col"])
    {
        return [[UMWebObjectCOL alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"colgroup"])
    {
        return [[UMWebObjectCOLGROUP alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"data"])
    {
        return [[UMWebObjectDATA alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"datalist"])
    {
        return [[UMWebObjectDATALIST alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"dd"])
    {
        return [[UMWebObjectDD alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"del"])
    {
        return [[UMWebObjectDEL alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"details"])
    {
        return [[UMWebObjectDETAILS alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"dfn"])
    {
        return [[UMWebObjectDFN alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"dialog"])
    {
        return [[UMWebObjectDIALOG alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"div"])
    {
        return [[UMWebObjectDIV alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"dl"])
    {
        return [[UMWebObjectDL alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"dt"])
    {
        return [[UMWebObjectDT alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"em"])
    {
        return [[UMWebObjectEM alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"embed"])
    {
        return [[UMWebObjectEMBED alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"fieldset"])
    {
        return [[UMWebObjectFIELDSET alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"figcaption"])
    {
        return [[UMWebObjectFIGCAPTION alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"footer"])
    {
        return [[UMWebObjectFOOTER alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"form"])
    {
        return [[UMWebObjectFORM alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"h1"])
    {
        return [[UMWebObjectH1 alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"h2"])
    {
        return [[UMWebObjectH2 alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"h3"])
    {
        return [[UMWebObjectH3 alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"h4"])
    {
        return [[UMWebObjectH4 alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"h5"])
    {
        return [[UMWebObjectH5 alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"h6"])
    {
        return [[UMWebObjectH6 alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"head"])
    {
        return [[UMWebObjectHEAD alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"header"])
    {
        return [[UMWebObjectHEADER alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"hgroup"])
    {
        return [[UMWebObjectHGROUP alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"hr"])
    {
        return [[UMWebObjectHR alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"i"])
    {
        return [[UMWebObjectI alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"iframe"])
    {
        return [[UMWebObjectIFRAME alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"img"])
    {
        return [[UMWebObjectIMG alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"input"])
    {
        return [[UMWebObjectINPUT alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"ins"])
    {
        return [[UMWebObjectINS alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"kbd"])
    {
        return [[UMWebObjectKBD alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"keygen"])
    {
        return [[UMWebObjectKEYGEN alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"label"])
    {
        return [[UMWebObjectLABEL alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"legend"])
    {
        return [[UMWebObjectLEGEND alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"li"])
    {
        return [[UMWebObjectLI alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"link"])
    {
        return [[UMWebObjectLINK alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"main"])
    {
        return [[UMWebObjectMAIN alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"map"])
    {
        return [[UMWebObjectMAP alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"mark"])
    {
        return [[UMWebObjectMARK alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"menu"])
    {
        return [[UMWebObjectMENU alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"menuitem"])
    {
        return [[UMWebObjectMENUITEM alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"meta"])
    {
        return [[UMWebObjectMETA alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"meter"])
    {
        return [[UMWebObjectMETER alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"nav"])
    {
        return [[UMWebObjectNAV alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"noscript"])
    {
        return [[UMWebObjectNOSCRIPT alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"object"])
    {
        return [[UMWebObjectOBJECT alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"ol"])
    {
        return [[UMWebObjectOL alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"optgroup"])
    {
        return [[UMWebObjectOPTGROUP alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"option"])
    {
        return [[UMWebObjectOPTION alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"output"])
    {
        return [[UMWebObjectOUTPUT alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"p"])
    {
        return [[UMWebObjectP alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"param"])
    {
        return [[UMWebObjectPARAM alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"picture"])
    {
        return [[UMWebObjectPICTURE alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"pre"])
    {
        return [[UMWebObjectPRE alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"progress"])
    {
        return [[UMWebObjectPROGRESS alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"q"])
    {
        return [[UMWebObjectQ alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"rp"])
    {
        return [[UMWebObjectRP alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"rt"])
    {
        return [[UMWebObjectRT alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"ruby"])
    {
        return [[UMWebObjectRUBY alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"s"])
    {
        return [[UMWebObjectS alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"samp"])
    {
        return [[UMWebObjectSAMP alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"script"])
    {
        return [[UMWebObjectSCRIPT alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"section"])
    {
        return [[UMWebObjectSECTION alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"select"])
    {
        return [[UMWebObjectSELECT alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"small"])
    {
        return [[UMWebObjectSMALL alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"source"])
    {
        return [[UMWebObjectSOURCE alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"span"])
    {
        return [[UMWebObjectSPAN alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"source"])
    {
        return [[UMWebObjectSOURCE alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"strike"])
    {
        return [[UMWebObjectSTRIKE alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"strong"])
    {
        return [[UMWebObjectSTRONG alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"style"])
    {
        return [[UMWebObjectSTYLE alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"sub"])
    {
        return [[UMWebObjectSUB alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"svg"])
    {
        return [[UMWebObjectSVG alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"table"])
    {
        return [[UMWebObjectTABLE alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"tbody"])
    {
        return [[UMWebObjectTBODY alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"td"])
    {
        return [[UMWebObjectTD alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"template"])
    {
        return [[UMWebObjectTEMPLATE alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"textarea"])
    {
        return [[UMWebObjectTEXTAREA alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"tfoot"])
    {
        return [[UMWebObjectTFOOT alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"th"])
    {
        return [[UMWebObjectTH alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"thead"])
    {
        return [[UMWebObjectTHEAD alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"time"])
    {
        return [[UMWebObjectTIME alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"title"])
    {
        return [[UMWebObjectTITLE alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"tr"])
    {
        return [[UMWebObjectTR alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"track"])
    {
        return [[UMWebObjectTRACK alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"u"])
    {
        return [[UMWebObjectU alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"ul"])
    {
        return [[UMWebObjectUL alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"var"])
    {
        return [[UMWebObjectVAR alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"video"])
    {
        return [[UMWebObjectVIDEO alloc]initWithWebObject:object];
    }
    else if([tag isEqualToString:@"wbr"])
    {
        return [[UMWebObjectWBR alloc]initWithWebObject:object];
    }
    return self;
}

- (NSString *)getAllText
{
    NSMutableString *s = [[NSMutableString alloc]init];
    for(UMWebObject *o in _children)
    {
        if([o isKindOfClass:[UMWebObjectPlaintext class]])
        {
            UMWebObjectPlaintext *pt = (UMWebObjectPlaintext *)o;
            [s appendString:pt.text];
        }
    }
    return s;
}

- (void)addText:(NSString *)str
{
    UMWebObjectPlaintext *pt = [[UMWebObjectPlaintext alloc]init];
    pt.noWrap = _noWrap;
    pt.text = str;
    [self addChild:pt];
}


+ (void)appendLineEndingToMutableString:(NSMutableString *)s
{
    [s appendString:@"\r\n"];
}

@end

