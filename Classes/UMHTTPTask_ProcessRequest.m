//
//  UMHTTPTask_ProcessRequest.m
//  ulib
//
//  Created by Andreas Fink on 13.02.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMHTTPTask_ProcessRequest.h"
#import "UMHTTPRequest.h"
#import "UMHTTPConnection.h"

@implementation UMHTTPTask_ProcessRequest

- (UMHTTPTask_ProcessRequest *)initWithRequest:(UMHTTPRequest *)xreq connection:(UMHTTPConnection *)xcon
{
    self = [super initWithName:@"UMHTTPTask_ProcessRequest"];
    if(self)
    {
        req = xreq;
        con = xcon;
    }
    return self;
}

- (void)main
{
    [con processHTTPRequest:req];
}
@end
