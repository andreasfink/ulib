//
//  NSData+UMHTTP.m
//  ulib
//
//  Created by Andreas Fink on 02.11.16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "NSData+UMHTTP.h"

@implementation NSData (UMHTTP)

- (NSString *)encodeBase64
{
    return [self base64EncodedStringWithOptions:0];
}

- (NSString *) urlencode
{
    static NSCharacterSet *allowedInUrl;
    if(allowedInUrl == NULL)
    {
        allowedInUrl = [NSCharacterSet characterSetWithCharactersInString:@"!$'()*,-.0123456789;ABCDEFGHIJKLMNOPQRSTUVWXYZ[]_abcdefghijklmnopqrstuvwxyz~"];
    }
    
    const char *bytes = self.bytes;
    NSMutableString *out = [[NSMutableString alloc]init];
    NSInteger i;
    NSInteger len = self.length;
    for(i=0;i<len;i++)
    {
        unsigned char c = bytes[i];
        if([allowedInUrl characterIsMember:(unichar)c])
        {
            [out appendFormat:@"%c",c];
        }
        else
        {
            [out appendFormat:@"%%%02x",(int)c];
        }
    }
    return out;
}
@end
