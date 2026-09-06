//
//  UMZMQSocket+ASN1.m
//  ulibasn1
//
//  Created by Andreas Fink on 12.07.22.
//  Copyright © 2022 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMZMQSocket+ASN1.h"

#import <ulibasn1/UMASN1Object.h>

@implementation UMZMQSocket(ASN1)

- (int)sendASN1:(UMASN1Object *)asn1 more:(BOOL)hasMore
{
    return [self sendData:[asn1 berEncoded] more:hasMore];
}

- (int)sendASN1:(UMASN1Object *)asn1
{
    return [self sendData:[asn1 berEncoded]];
}

- (UMASN1Object *)receiveASN1
{
    NSData *d = [self receiveData];
    return [[UMASN1Object alloc]initWithBerData:d];
}

- (UMASN1Object *)receiveASN1AndMore:(BOOL *)more
{
    NSData *d = [self receiveDataAndMore:more];
    return [[UMASN1Object alloc]initWithBerData:d];
}

@end
