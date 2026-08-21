//
//  UMStdIo.m
//  ulib
//
//  Created by Andreas Fink on 20.08.2026.
//

#include <stdio.h>
#include <string.h>

#import <ulib/UMStdIo.h>
#import <ulib/NSData+ulib.h>


@implementation UMStdIo

- (UMStdIo *)initWithInput:(FILE *)in output:(FILE *)out error:(FILE *)err;
{
    self = [super init];
    if(self)
    {
        _in = in;
        _out = out;
        _err = err;
    }
    return self;
}

- (UMStdIo *)init
{
    return [self initWithInput:stdin output:stdout error:stderr];
}

- (int)writeString:(NSString *)s
{
    return fprintf(_out,"%s",s.UTF8String);
}

- (int)writeStringNL:(NSString *)s
{
    return fprintf(_out,"%s\n",s.UTF8String);
}

- (int)writeErrorString:(NSString *)s
{
    return fprintf(_err,"%s",s.UTF8String);
}

- (int)writeErrorStringNL:(NSString *)s
{
    return fprintf(_err,"%s\n",s.UTF8String);
}


- (unsigned long)readShortLine:(NSString **)out
{
    char buffer[1024];
    memset (buffer,0x00,sizeof(buffer));
    char *s = fgets(&buffer[0], sizeof(buffer)-1, _in);
    if(s)
    {
        unsigned long len = strlen(s);
        if((len>0) && ((s[len-1]=='\n') || (s[len-1]=='\r')))
        {
            len--;
        }
        if((len>0) && ((s[len-1]=='\n') || (s[len-1]=='\r')))
        {
            len--;
        }
        NSData *d = [NSData dataWithBytes:s length:len];
        if(out)
        {
            *out = [d stringValue];
        }
        return len;
    }
    return errno;
}

@end
