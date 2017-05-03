//
//  UMHTTPSServer.h
//  ulib
//
//  Created by Andreas Fink on 02.05.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMHTTPServer.h"

@interface UMHTTPSServer : UMHTTPServer

- (id) initWithPort:(in_port_t)port
         sslKeyFile:(NSString *)sslKeyFile
        sslCertFile:(NSString *)sslCertFile;

- (id) initWithPort:(in_port_t)port
         sslKeyFile:(NSString *)sslKeyFile
        sslCertFile:(NSString *)sslCertFile
          taskQueue:(UMTaskQueue *)tq;

- (id) initWithPort:(in_port_t)port
         socketType:(UMSocketType)type
         sslKeyFile:(NSString *)sslKeyFile
        sslCertFile:(NSString *)sslCertFile
          taskQueue:(UMTaskQueue *)tq;

- (id) initWithPort:(in_port_t)port
         socketType:(UMSocketType)type
                ssl:(BOOL)doSSL
         sslKeyFile:(NSString *)sslKeyFile
        sslCertFile:(NSString *)sslCertFile
          taskQueue:(UMTaskQueue *)tq;
@end
