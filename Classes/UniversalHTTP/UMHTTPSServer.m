//
//  UMHTTPSServer.m
//  ulib
//
//  Created by Andreas Fink on 02.05.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMHTTPSServer.h"

@implementation UMHTTPSServer


- (id) initWithPort:(in_port_t)port
         sslKeyFile:(NSString *)sslKeyFile
        sslCertFile:(NSString *)sslCertFile
{
    return [self initWithPort:port
                   sslKeyFile:sslKeyFile
                  sslCertFile:sslCertFile
                    taskQueue:NULL];
}

- (id) initWithPort:(in_port_t)port
         sslKeyFile:(NSString *)sslKeyFile
        sslCertFile:(NSString *)sslCertFile
          taskQueue:(UMTaskQueue *)tq
{

    if((sslKeyFile==NULL) || (sslCertFile==NULL))
    {
        NSLog(@"HTTPS_CERTIFICATE_MISSING");
        return NULL;
    }
    self = [super initWithPort:port
                    socketType:UMSOCKET_TYPE_TCP
                           ssl:YES
                    sslKeyFile:sslKeyFile
                   sslCertFile:sslCertFile
                     taskQueue:tq];
    if(self)
    {
        _enableSSL = YES;
    }
    return self;
}

- (id) initWithPort:(in_port_t)port
         socketType:(UMSocketType)type
         sslKeyFile:(NSString *)sslKeyFile
        sslCertFile:(NSString *)sslCertFile
          taskQueue:(UMTaskQueue *)tq
{
    if((sslKeyFile==NULL) || (sslCertFile==NULL))
    {
        @throw([NSException exceptionWithName:@"HTTPS_CERTIFICATE_MISSING" reason:@"call initWithPort:sslKeyFile:sslCertFile:sslCertFile and not init on UMHTTPSServer"
                                     userInfo:NULL ]);
    }
    BOOL doSSL;

    if((sslKeyFile==NULL) || (sslCertFile==NULL))
    {
        doSSL=NO;
    }
    else
    {
        doSSL=YES;
    }
    self = [super initWithPort:port
                    socketType:type
                           ssl:doSSL
                    sslKeyFile:sslKeyFile
                   sslCertFile:sslCertFile
                     taskQueue:tq];
    if(self)
    {
        _enableSSL = YES;
    }
    return self;
}


- (id) initWithPort:(in_port_t)port
         socketType:(UMSocketType)type
                ssl:(BOOL)doSSL
         sslKeyFile:(NSString *)sslKeyFile
        sslCertFile:(NSString *)sslCertFile
          taskQueue:(UMTaskQueue *)tq
{
    if((doSSL==YES) && ((sslKeyFile==NULL) || (sslCertFile==NULL)))
    {
        @throw([NSException exceptionWithName:@"HTTPS_CERTIFICATE_MISSING" reason:@"call initWithPort:sslKeyFile:sslCertFile:sslCertFile and not init on UMHTTPSServer"
                                     userInfo:NULL ]);
    }
    self = [super initWithPort:port
                    socketType:type
                           ssl:doSSL
                    sslKeyFile:sslKeyFile
                   sslCertFile:sslCertFile
                     taskQueue:tq];
    if(self)
    {
    }
    return self;
}

@end
