//
//  UMASN1Choice.h
//  ulibasn1
//
//  Created by Andreas Fink on 03.07.14.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulibasn1/UMASN1Object.h>

typedef enum    UMASN1ChoiceType
{
    UMASN1ChoiceType_unknownEncoded = 0,
    UMASN1ChoiceType_implicitlyEncoded = 1,
    UMASN1ChoiceType_explicitlyEncoded = 2,
} UMASN1ChoiceType;

@interface UMASN1Choice : UMASN1Object
{
    UMASN1ChoiceType _choiceType;
}

@property(readwrite) UMASN1ChoiceType choiceType;

- (void)cloneFrom:(UMASN1Object *)other;

@end
