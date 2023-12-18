//
//  NSData+ulib.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/NSData+ulib.h>
#import <ulib/NSMutableData+ulib.h>
#import <ulib/NSString+ulib.h>
#ifndef _POSIX_SOURCE
#define _POSIX_SOURCE    1
#endif
#include <sys/types.h>
#include <unistd.h>
#include <openssl/sha.h>
#include <stdint.h>

@implementation NSData(ulib)

- (NSString *)hierarchicalDescriptionWithPrefix:(NSString *)prefix
{
	ssize_t i;
	ssize_t n;
	const uint8_t *ptr;
	
	NSMutableString *s = [NSMutableString stringWithFormat:@"%@NSData",prefix];

	prefix = [prefix increasePrefix];
	
	ptr = [self bytes];
	n   = [self length];
	for(i=0;i<n;i++)
	{
		if((i%16)==0)
			[s appendFormat:@"\n%@",prefix];
		[s appendFormat:@" %02X",ptr[i]];
	}
	[s appendString:@"\n"];
	return s;
}

- (NSString *)dump
{
	return [self stringForDumping];
}

- (NSString *)stringForDumping
{
	ssize_t i;
	ssize_t n;
	const uint8_t *ptr;
	uint8_t	octet;

	ptr = [self bytes];
	n   = [self length];

	NSMutableString *s = [[NSMutableString alloc]init];	
	[s appendFormat:@"NSData [len=%ld] [bytes=",n];
	
	for(i=0;i<n;i++)
	{
		octet = ptr[i];
		[s appendFormat:@" %02X",octet];
	}
	[s appendString:@"]\n"];
	return s;
}

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

- (NSString *)stringValue
{
    return [[NSString alloc]initWithData:self encoding:NSUTF8StringEncoding];
}

#if defined(LINUX) || defined(FREEBSD)
/* this stuff is not in Gnustep but in OSX so we emulate it here */

#ifdef OLD_GNUSTEP

        // this is now implemented in gnustep base
- (NSRange)rangeOfData:(NSData *)dataToFind options:(NSDataSearchOptions)mask range:(NSRange)searchRange
{
    const void * bytes = [self bytes];
    NSUInteger length = [self length];
    
    const void * searchBytes = [dataToFind bytes];
    NSUInteger searchLength = [dataToFind length];
    NSUInteger searchIndex = 0;
    
    NSRange foundRange = {NSNotFound, searchLength};
    NSUInteger index;
    for (index = searchIndex; index < length; ++index)
    {
        if (((char *)bytes)[index] == ((char *)searchBytes)[searchIndex])
        {
            //the current character matches
            if (foundRange.location == NSNotFound)
            {
                foundRange.location = index;
            }
            ++searchIndex;
            if (searchIndex >= searchLength)
            {
                return foundRange;
            }
        }
        else
        {
            searchIndex = 0;
            foundRange.location = NSNotFound;
        }
    }
    return foundRange;
}
#endif
#endif

- (NSRange) rangeOfData_dd:(NSData *)dataToFind
{
    return [self rangeOfData_dd:dataToFind startingFrom:0];
}

- (NSRange) rangeOfData_dd:(NSData *)dataToFind startingFrom:(long)start
{
    const void * bytes = [self bytes];
    NSInteger length = [self length];
    NSRange foundRange = {NSNotFound, 0};


    length = length - dataToFind.length +1;
    if(length<1)
    {
        return foundRange;
    }

    for (NSInteger index = start; index < length;index++)
    {
        if(memcmp (&bytes[index], dataToFind.bytes,dataToFind.length)==0)
        {
            foundRange.location =index;
            foundRange.length = dataToFind.length;
            return foundRange;
        }
    }
    return foundRange;
}


- (NSString *)hexString
{
    NSMutableString *result;
    int i;
    NSUInteger n;
    result = [[NSMutableString alloc]init];
    n = [self length];
    for(i=0;i<n;i++)
    {
        [result appendFormat:@"%02X",((unsigned char *)[self bytes])[i]];
    }
    return result;
}

- (NSData *)hex
{
    NSMutableData *r;
    NSData *result;
    int i;
    NSUInteger n;
    const unsigned char *src;
    char *dst;
    
    r = [[NSMutableData alloc] initWithCapacity: 2 * [self length]];
    n = [self length];
    src = [self bytes];
    dst = [r mutableBytes];
    for(i=0;i<n;i++)
    {
        snprintf(&dst[i*2],2,"%02X",src[i]);
    }
    result = [NSData dataWithData: r];
    return result;
}

static inline int nibbleToInt(const char a)
{
    if((a>='0') && (a<='9'))
        return (a-'0');
    if((a>='a') && (a<='f'))
        return (a-'a'+10);
    if((a>='A') && (a<='F'))
        return (a-'A'+10);
    return 0;
}
            
- (NSData *)unhexedData
{
    int i;
    NSUInteger n = [self length]/2;
    NSMutableData *out = [[NSMutableData alloc]initWithCapacity:n];
    const unsigned char *bytes = [self bytes];
    unsigned char a;
    unsigned char b;
    unsigned char c;
    for(i=0;i<n;i ++)
    {
        a = bytes[2*i];
        b = bytes[2*i+1];
        c = nibbleToInt(a)<<4 | nibbleToInt(b);
        [out appendBytes:&c length:1];
    }
    return out;
}

- (unsigned long)crc
{
    const unsigned long crctab[] =
    {
        0x7fffffff,
        0x77073096,  0xee0e612c,  0x990951ba,  0x076dc419,  0x706af48f,
        0xe963a535,  0x9e6495a3,  0x0edb8832,  0x79dcb8a4,  0xe0d5e91e,
        0x97d2d988,  0x09b64c2b,  0x7eb17cbd,  0xe7b82d07,  0x90bf1d91,
        0x1db71064,  0x6ab020f2,  0xf3b97148,  0x84be41de,  0x1adad47d,
        0x6ddde4eb,  0xf4d4b551,  0x83d385c7,  0x136c9856,  0x646ba8c0,
        0xfd62f97a,  0x8a65c9ec,  0x14015c4f,  0x63066cd9,  0xfa0f3d63,
        0x8d080df5,  0x3b6e20c8,  0x4c69105e,  0xd56041e4,  0xa2677172,
        0x3c03e4d1,  0x4b04d447,  0xd20d85fd,  0xa50ab56b,  0x35b5a8fa,
        0x42b2986c,  0xdbbbc9d6,  0xacbcf940,  0x32d86ce3,  0x45df5c75,
        0xdcd60dcf,  0xabd13d59,  0x26d930ac,  0x51de003a,  0xc8d75180,
        0xbfd06116,  0x21b4f4b5,  0x56b3c423,  0xcfba9599,  0xb8bda50f,
        0x2802b89e,  0x5f058808,  0xc60cd9b2,  0xb10be924,  0x2f6f7c87,
        0x58684c11,  0xc1611dab,  0xb6662d3d,  0x76dc4190,  0x01db7106,
        0x98d220bc,  0xefd5102a,  0x71b18589,  0x06b6b51f,  0x9fbfe4a5,
        0xe8b8d433,  0x7807c9a2,  0x0f00f934,  0x9609a88e,  0xe10e9818,
        0x7f6a0dbb,  0x086d3d2d,  0x91646c97,  0xe6635c01,  0x6b6b51f4,
        0x1c6c6162,  0x856530d8,  0xf262004e,  0x6c0695ed,  0x1b01a57b,
        0x8208f4c1,  0xf50fc457,  0x65b0d9c6,  0x12b7e950,  0x8bbeb8ea,
        0xfcb9887c,  0x62dd1ddf,  0x15da2d49,  0x8cd37cf3,  0xfbd44c65,
        0x4db26158,  0x3ab551ce,  0xa3bc0074,  0xd4bb30e2,  0x4adfa541,
        0x3dd895d7,  0xa4d1c46d,  0xd3d6f4fb,  0x4369e96a,  0x346ed9fc,
        0xad678846,  0xda60b8d0,  0x44042d73,  0x33031de5,  0xaa0a4c5f,
        0xdd0d7cc9,  0x5005713c,  0x270241aa,  0xbe0b1010,  0xc90c2086,
        0x5768b525,  0x206f85b3,  0xb966d409,  0xce61e49f,  0x5edef90e,
        0x29d9c998,  0xb0d09822,  0xc7d7a8b4,  0x59b33d17,  0x2eb40d81,
        0xb7bd5c3b,  0xc0ba6cad,  0xedb88320,  0x9abfb3b6,  0x03b6e20c,
        0x74b1d29a,  0xead54739,  0x9dd277af,  0x04db2615,  0x73dc1683,
        0xe3630b12,  0x94643b84,  0x0d6d6a3e,  0x7a6a5aa8,  0xe40ecf0b,
        0x9309ff9d,  0x0a00ae27,  0x7d079eb1,  0xf00f9344,  0x8708a3d2,
        0x1e01f268,  0x6906c2fe,  0xf762575d,  0x806567cb,  0x196c3671,
        0x6e6b06e7,  0xfed41b76,  0x89d32be0,  0x10da7a5a,  0x67dd4acc,
        0xf9b9df6f,  0x8ebeeff9,  0x17b7be43,  0x60b08ed5,  0xd6d6a3e8,
        0xa1d1937e,  0x38d8c2c4,  0x4fdff252,  0xd1bb67f1,  0xa6bc5767,
        0x3fb506dd,  0x48b2364b,  0xd80d2bda,  0xaf0a1b4c,  0x36034af6,
        0x41047a60,  0xdf60efc3,  0xa867df55,  0x316e8eef,  0x4669be79,
        0xcb61b38c,  0xbc66831a,  0x256fd2a0,  0x5268e236,  0xcc0c7795,
        0xbb0b4703,  0x220216b9,  0x5505262f,  0xc5ba3bbe,  0xb2bd0b28,
        0x2bb45a92,  0x5cb36a04,  0xc2d7ffa7,  0xb5d0cf31,  0x2cd99e8b,
        0x5bdeae1d,  0x9b64c2b0,  0xec63f226,  0x756aa39c,  0x026d930a,
        0x9c0906a9,  0xeb0e363f,  0x72076785,  0x05005713,  0x95bf4a82,
        0xe2b87a14,  0x7bb12bae,  0x0cb61b38,  0x92d28e9b,  0xe5d5be0d,
        0x7cdcefb7,  0x0bdbdf21,  0x86d3d2d4,  0xf1d4e242,  0x68ddb3f8,
        0x1fda836e,  0x81be16cd,  0xf6b9265b,  0x6fb077e1,  0x18b74777,
        0x88085ae6,  0xff0f6a70,  0x66063bca,  0x11010b5c,  0x8f659eff,
        0xf862ae69,  0x616bffd3,  0x166ccf45,  0xa00ae278,  0xd70dd2ee,
        0x4e048354,  0x3903b3c2,  0xa7672661,  0xd06016f7,  0x4969474d,
        0x3e6e77db,  0xaed16a4a,  0xd9d65adc,  0x40df0b66,  0x37d83bf0,
        0xa9bcae53,  0xdebb9ec5,  0x47b2cf7f,  0x30b5ffe9,  0xbdbdf21c,
        0xcabac28a,  0x53b39330,  0x24b4a3a6,  0xbad03605,  0xcdd70693,
        0x54de5729,  0x23d967bf,  0xb3667a2e,  0xc4614ab8,  0x5d681b02,
        0x2a6f2b94,  0xb40bbe37,  0xc30c8ea1,  0x5a05df1b,  0x2d02ef8d
    };
    
    unsigned long i = 0;
    NSUInteger nr = 0;
    unsigned long step = 0;
    const unsigned char *p;
    unsigned long crcv;
    
    crcv = 0;
    step = 0;
    nr  = [self length];
    for (p = [self bytes]; nr--; p++)
    {
        if (!(i = crcv >> 24L ^ *p))
        {
            i = step++;
            if (step >= sizeof(crctab)/sizeof(crctab[0]))
            {
                step = 0;
            }
        }
        crcv = ((crcv << 8) ^ crctab[i]) & 0xffffffff;
    }
    return crcv;
}

-(NSData *)sha1
{
    unsigned char obuf[SHA_DIGEST_LENGTH];
    SHA1(self.bytes, self.length, obuf);
    return [NSData dataWithBytes:obuf length:SHA_DIGEST_LENGTH];
}

- (NSData *)sha224
{
    unsigned char obuf[SHA224_DIGEST_LENGTH];
    SHA224(self.bytes, self.length, obuf);
    return [NSData dataWithBytes:obuf length:SHA224_DIGEST_LENGTH];
}


- (NSData *)sha256
{
    unsigned char obuf[SHA256_DIGEST_LENGTH];
    SHA256(self.bytes, self.length, obuf);
    return [NSData dataWithBytes:obuf length:SHA256_DIGEST_LENGTH];
}


- (NSData *)sha384
{
    unsigned char obuf[SHA384_DIGEST_LENGTH];
    SHA384(self.bytes, self.length, obuf);
    return [NSData dataWithBytes:obuf length:SHA384_DIGEST_LENGTH];
}


- (NSData *)sha512
{
    unsigned char obuf[SHA512_DIGEST_LENGTH];
    SHA512(self.bytes, self.length, obuf);
    return [NSData dataWithBytes:obuf length:SHA512_DIGEST_LENGTH];
}

- (NSData *)xor:(NSData *)xor
{

    NSMutableData *out = [[NSMutableData alloc]init];
    NSInteger xor_max = xor.length;
    NSInteger in_max = self.length;
    uint8_t *in_bytes = (uint8_t *)self.bytes;
    uint8_t *xor_bytes = (uint8_t *)xor.bytes;

    for(NSInteger in_idx = 0; in_idx < in_max;in_idx++)
    {
        uint8_t inval = in_bytes[in_idx];
        uint8_t xval = xor_bytes[in_idx % xor_max];
        uint8_t outval = inval ^ xval;
        [out appendByte:outval];
    }
    return out;
}

- (NSString *)utf8String
{
    return [[NSString alloc]initWithData:self encoding:NSUTF8StringEncoding];
}



@end
