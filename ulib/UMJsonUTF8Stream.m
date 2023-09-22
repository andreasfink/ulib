//
//  UMJSonUTF8Stream.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import <ulib/UMJsonUTF8Stream.h>


@implementation UMJsonUTF8Stream

@synthesize index = _index;

- (id)init
{
    self = [super init];
    if(self)
	{
        _data = [[NSMutableData alloc] initWithCapacity:4096u];
    }
    return self;
}


- (void)appendData:(NSData *)data_
{
    
    if (_index)
    {
        // Discard data we've already parsed
		[_data replaceBytesInRange:NSMakeRange(0, _index) withBytes:"" length:0];
        
        // Reset index to point to current position
		_index = 0;
	}
    
    [_data appendData:data_];
    
    // This is an optimisation. 
    _bytes = (const char*)[_data bytes];
    _length = [_data length];
}


- (BOOL)getUnichar:(unichar*)ch
{
    if (_index < _length)
    {
        *ch = (unichar)_bytes[_index];
        return YES;
    }
    return NO;
}

- (BOOL)getNextUnichar:(unichar*)ch
{
    if (++_index < _length)
    {
        *ch = (unichar)_bytes[_index];
        return YES;
    }
    return NO;
}

- (BOOL)getStringFragment:(NSString **)string
{
    NSUInteger start = _index;
    while (_index < _length)
    {
        switch (_bytes[_index])
        {
            case '"':
            case '\\':
            case 0 ... 0x1f:
                *string = [[NSString alloc] initWithBytes:(_bytes + start)
                                                   length:(_index - start)
                                                 encoding:NSUTF8StringEncoding];
                return YES;
                break;
            default:
                _index++;
                break;
        }
    }
    return NO;
}

- (void)skip
{
    _index++;
}

- (void)skipWhitespace
{
    while (_index < _length)
    {
        switch (_bytes[_index])
        {
            case ' ':
            case '\t':
            case '\r':
            case '\n':
                _index++;
                break;
            default:
                return;
                break;
        }
    }
}

- (BOOL)haveRemainingCharacters:(NSUInteger)chars
{
    return [_data length] - _index >= chars;
}

- (BOOL)skipCharacters:(const char *)chars length:(NSUInteger)len
{
    const void *bytes = ((const char*)[_data bytes]) + _index;
    if (!memcmp(bytes, chars, len))
    {
        _index += len;
        return YES;
    }
    return NO;
}

- (NSString*)stringWithRange:(NSRange)range
{
    return [[NSString alloc] initWithBytes:_bytes + range.location length:range.length encoding:NSUTF8StringEncoding];
}


@end
