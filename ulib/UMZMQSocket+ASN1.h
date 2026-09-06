//
//  UMZMQSocket+ASN1.h
//  ulibasn1
//
//  Created by Andreas Fink on 12.07.22.
//  Copyright © 2022 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>

@class UMASN1Object;

@interface UMZMQSocket (ASN1)

- (int)sendASN1:(UMASN1Object *)asn1 more:(BOOL)hasMore;
- (int)sendASN1:(UMASN1Object *)asn1;
- (UMASN1Object *)receiveASN1;
- (UMASN1Object *)receiveASN1AndMore:(BOOL *)more;

@end

