//
//  UMASN1EndOfContents.m
//  ulibasn1
//
//  Created by Andreas Fink on 03.07.14.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.


#import <ulibasn1/UMASN1EndOfContents.h>

@implementation UMASN1EndOfContents

- (UMASN1EndOfContents *)init
{
    self = [super init];
    if(self)
    {
    }
    return self;
}

- (void)appendToMutableData:(NSMutableData *)d
{
    uint8_t bytes[2] = { 0x00,0x00 };
    [d appendBytes:&bytes length:2];
}

- (NSString *)description
{
    return @"END_OF_CONTENTS";
}

- (NSString *)objectName
{
    return @"END_OF_CONTENTS";
}

- (id) objectValue
{
    return @"";
}

+ (uint64_t)classTagNumber
{
    return -3;
}

+ (BOOL)tagMatches:(uint64_t)tag
{
    return tag == 0;
}

+ (BOOL)tagMatch:(UMASN1Tag *)t
{
    if((t.tagClass == UMASN1Class_Universal) && (t.tagNumber = 0))
    {
        return YES;
    }
    return NO;
}

@end
