//
//  UMWebObjectPlaintext.m
//  ulib
//
//  Created by Andreas Fink on 16.10.2026.
//

#import "UMWebObjectPlaintext.h"

@implementation UMWebObjectPlaintext

- (UMWebObjectPlaintext *)init
{
    self = [super init];
    if(self)
    {
        self.tag = @"";
        _text=@"";
    }
    return self;
}

- (NSString *)htmlString:(BOOL)humanReadable
                   ident:(int)ident
                   flags:(UMWebObjectFlags)flags
{
    if((flags & UMWebObjectFlag_PRE) || (humanReadable==NO) || _noWrap)
    {
        return _text;
    }
    NSArray *lines = [_text componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSString *identString = [UMWebObject identOfLevel:ident];
    NSMutableString *out = [[NSMutableString alloc]init];
    BOOL first=YES;
    for(NSString *line in lines)
    {
        if(!first)
        {
            [out appendFormat:@"\n%@%@",identString,line];
        }
        else
        {
            [out appendFormat:@"%@%@",identString,line];
            first=NO;
        }
    }
    return out;
}

@end
