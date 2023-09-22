//
//  UMHTTPServerAuthoriseResult.h
//  UniversalHTTP
//
//  Created by Andreas Fink on 09.01.09.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//



typedef enum UMHTTPServerAuthoriseResult
{
	UMHTTPServerAuthorise_successful = 0,
	UMHTTPServerAuthorise_failed = 1,
	UMHTTPServerAuthorise_blacklisted = 2,
} UMHTTPServerAuthoriseResult;
