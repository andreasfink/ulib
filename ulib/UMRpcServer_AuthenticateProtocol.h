//
//  UMRpcServer_AuthenticateProtocol.h
//  ulibasn1
//
//  Created by Andreas Fink on 21.08.2026.
//

#import <ulibasn1/UMRpcError.h>
@class UMRpcSession;

@protocol UMRpcServer_AuthenticateProtocol<NSObject>

- (UMRpcError) login:(NSString *)user
            password:(NSString *)password
                host:(NSString *)address
            instance:(NSString *)instance
             session:(UMRpcSession *)session;
@end

