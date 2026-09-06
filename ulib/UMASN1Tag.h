//
//  UMASN1Tag.h
//  ulibasn1
//
//  Created by Andreas Fink on 02.07.14.
//  //  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>

typedef enum UMASN1ClassType
{
    UMASN1Class_Universal       = 0b00,
    UMASN1Class_Application     = 0b01,
    UMASN1Class_ContextSpecific = 0b10,
    UMASN1Class_Private         = 0b11,
} UMASN1ClassType;

/* from http://luca.ntop.org/Teaching/Appunti/asn1.html */
/* and http://obj-sys.com/asn1tutorial/node124.html */

typedef enum UMASN1PrimitiveType
{
    UMASN1Primitive_choice                          = 0, /* dummy, you would never see this in the wild */
    UMASN1Primitive_boolean                         = 1,
    UMASN1Primitive_integer                         = 2,
    UMASN1Primitive_bitstring                       = 3,
    UMASN1Primitive_octetstring                     = 4,
    UMASN1Primitive_null                            = 5,
    UMASN1Primitive_object_identifier               = 6,
    UMASN1Primitive_object_descriptor               = 7,
    UMASN1Primitive_external                        = 8,
    UMASN1Primitive_real                            = 9,
    UMASN1Primitive_enumerated                      = 10,
    UMASN1Primitive_embedded_pdv                    = 11,
    UMASN1Primitive_UTF8String                      = 12,
    UMASN1Primitive_relative_object_identifier      = 13,
    UMASN1Primitive_time                            = 14,
    UMASN1Primitive_reserved15                      = 15,
    UMASN1Primitive_sequence                        = 16, /* sequence and sequency of */
    UMASN1Primitive_set_of                          = 17, /* set and set of */
    UMASN1Primitive_numeric_string                  = 18,
    UMASN1Primitive_printable_string                = 19,
    UMASN1Primitive_t61_string                      = 20,
    UMASN1Primitive_videotex_string                 = 21,
    UMASN1Primitive_ia5_string                      = 22,
    UMASN1Primitive_utc_time                        = 23,
    UMASN1Primitive_generalized_time                = 24,
    UMASN1Primitive_graphic_string                  = 25,
    UMASN1Primitive_visible_string                  = 26,
    UMASN1Primitive_general_string                  = 27,
    UMASN1Primitive_universal_string                = 28,
    UMASN1Primitive_unrestricted_character_string   = 29,
    UMASN1Primitive_bmp_string                      = 30,
    UMASN1Primitive_date                            = 31,
    UMASN1Primitive_time_of_day                     = 32,
    UMASN1Primitive_date_time                       = 33,
    UMASN1Primitive_duration                        = 34,
    UMASN1Primitive_oid_internationalized           = 35,
    UMASN1Primitive_relative_oid_internationalized  = 36,
} UMASN1PrimitiveType;


typedef enum UMASN1PrimitiveOrConstructed
{
    UMASN1Primitive             = 0x00,
    UMASN1Constructed           = 0x20
} UMASN1PrimitiveOrConstructed;

typedef NSInteger   UMASN1TagNumber;

/*!
 @class UMASN1Tag
 @brief  UMASN1Tag represents the ASN1 tag of a PDU
 
 */

@interface  UMASN1Tag : UMObject
{
    UMASN1ClassType                 _tagClass;       /*!< Universal,Application,ContextSpecific,Private  */
    BOOL                            _isConstructed;  /*!< if its a sequence of other objects or not */
    uint64_t                        _tagNumber;      /*!< the tag number is always positive */
}

@property (readwrite,assign) UMASN1ClassType    tagClass;
@property (readwrite,assign) uint64_t           tagNumber;
@property (readwrite,assign) BOOL               isConstructed;

- (BOOL) tagIsPrimitive;
- (BOOL) tagIsConstructed;
- (void) setTagIsConstructed;
- (void) setTagIsPrimitive;

- (UMASN1Tag *)initWithBerData:(NSData *)data atPosition:(NSUInteger *)pos context:(id)context;
- (NSData *) berEncoded;
- (NSString *)name;

@end
