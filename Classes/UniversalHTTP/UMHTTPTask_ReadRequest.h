//
//  UMHTTPTask_ReadRequest.h
//  ulib
//
//  Created by Andreas Fink on 13.02.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMTask.h"

@class UMHTTPConnection;

@interface UMHTTPTask_ReadRequest : UMTask
{
    UMHTTPConnection *con;
}

- (UMHTTPTask_ReadRequest *)initWithConnection:(UMHTTPConnection *)xcon;
- (void)main;


@end
