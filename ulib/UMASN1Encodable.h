//
//  UMASN1Encodable.h
//  ulibasn1
//
//  Created by Andreas Fink on 19.05.2025.
//  Copyright © 2025 Andreas Fink (andreas@fink.org). All rights reserved.
//


@protocol UMASN1Encodable <UMObject>

@class UMASN1Tag;
@class UMASN1Length;
typedef enum UMASN1EncodingType;

@property(readwrite,strong) UMASN1Tag           *asn1_tag;
@property(readwrite,strong) UMASN1Length        *asn1_length;
@property(readwrite,strong) NSData              *asn1_data;
@property(readwrite,strong) NSMutableArray      *asn1_list;
@property(readwrite,assign) enum UMASN1EncodingType  encodingType;

- (UMASN1Object *)initWithASN1Object:(UMASN1Object *)obj context:(id)context encoding:(UMASN1EncodingType)encodingType;
- (UMASN1Object *)initWithASN1Object:(UMASN1Object *)obj context:(id)context;
- (UMASN1Object *)initWithBerData:(NSData *)data;
- (UMASN1Object *)initWithBerData:(NSData *)data atPosition:(NSUInteger *)pos context:(id)context;
- (UMASN1Object *)readBerData:(NSData *)data atPosition:(NSUInteger *)pos context:(id)context;
- (NSString *)objectName;
- (id)objectValue;
- (NSString *)objectOperation;
- (UMASN1Object *)processAfterDecodeWithContext:(id)context;

- (BOOL)isEndOfContents;
- (UMASN1Object *)getObjectAtPosition:(NSUInteger)pos;
- (UMASN1Object *)getObjectWithTagNumber:(NSUInteger)nr;
- (UMASN1Object *)getObjectWithTagNumber:(NSUInteger)nr startingAtPosition:(NSUInteger)start;

- (UMASN1Object *)getPrivateObjectWithTagNumber:(NSUInteger)nr;
- (UMASN1Object *)getUniversalObjectWithTagNumber:(NSUInteger)nr;
- (UMASN1Object *)getApplicationSpecificObjectWithTagNumber:(NSUInteger)nr;
- (UMASN1Object *)getContextSpecificObjectWithTagNumber:(NSUInteger)nr;

- (NSString *)stringValue;
- (NSString *)imsiValue;
- (NSString *)isdnValue;
- (NSString *)rawDataAsStringValue;

- (NSData *)berEncoded;
- (void)processBeforeEncode;

+ (uint64_t)classTagNumber;
+ (BOOL)tagMatches:(uint64_t)tag;
+ (BOOL)tagMatch:(UMASN1Tag *)t;

- (id)proxyForJson;
- (NSString *)jsonString;
- (NSString *)jsonCompactString;

+ (void)asn1DefAppendString:(NSMutableString *)o
                       len:(NSInteger)len
                       tag:(NSInteger)tag
                  dictname:(const char *)dictname
                   options:(const char *)options
                      type:(const char *)type;
@end

