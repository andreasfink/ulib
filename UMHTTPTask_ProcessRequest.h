//
//  UMHTTPTask_ProcessRequest.h
//  ulib
//
//  Created by Andreas Fink on 13.02.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMTask.h"
@class UMHTTPRequest;
@class UMHTTPConnection;

@interface UMHTTPTask_ProcessRequest : UMTask
{
    UMHTTPRequest *req;
    UMHTTPConnection *con;
}


- (UMHTTPTask_ProcessRequest *)initWithRequest:(UMHTTPRequest *)xreq connection:(UMHTTPConnection *)xcon;
- (void)main;


@end
