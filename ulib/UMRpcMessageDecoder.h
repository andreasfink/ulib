//
//  UMRpcMessageDecoder.h
//  ulibasn1
//
//  Created by Andreas Fink on 22.08.2026.
//

#import <ulib/UMRpcMessage.h>


@interface UMRpcMessageDecoder : UMObject

- (UMSynchronizedSortedDictionary *)standardMessageTypes;
- (UMRpcMessage *)decodeMessage:(UMRpcMessage *)msgin;

@end

