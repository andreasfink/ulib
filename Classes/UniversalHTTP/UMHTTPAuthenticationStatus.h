//
//  UMHTTPAuthenticationStatus.h
//  ulib
//
//  Created by Andreas Fink on 01.11.16.
//  Copyright © 2016 Andreas Fink. All rights reserved.
//

typedef enum UMHTTPAuthenticationStatus
{
    UMHTTP_AUTHENTICATION_STATUS_UNTESTED = 0,
    UMHTTP_AUTHENTICATION_STATUS_FAILED,
    UMHTTP_AUTHENTICATION_STATUS_PASSED,
    UMHTTP_AUTHENTICATION_STATUS_NOT_REQUESTED,
} UMHTTPAuthenticationStatus;
