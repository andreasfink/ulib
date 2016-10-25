//
//  UMHTTPServerAuthorizeResult.h
//  UniversalHTTP
//
//  Created by Andreas Fink on 09.01.09.
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//



typedef enum UMHTTPServerAuthorizeResult
{
	UMHTTPServerAuthorize_successful = 0,
	UMHTTPServerAuthorize_failed = 1,
	UMHTTPServerAuthorize_blacklisted = 2,
} UMHTTPServerAuthorizeResult;
