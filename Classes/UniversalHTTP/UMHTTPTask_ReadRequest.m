//
//  UMHTTPTask_ReadReqest.m
//  ulib
//
//  Created by Andreas Fink on 13.02.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMHTTPTask_ReadRequest.h"
#import "UMHTTPConnection.h"
#import "UMHTTPServer.h"

@implementation UMHTTPTask_ReadRequest


- (UMHTTPTask_ReadRequest *)initWithConnection:(UMHTTPConnection *)xcon
{
    self = [super initWithName:@"UMHTTPTask_ReadRequest"];
    if(self)
    {
        con = xcon;
    }
    return self;
}

- (void)main
{
    @autoreleasepool
    {
        [con connectionListener];
    }
}
@end
