//
//  UMRpcSessionHandler.h
//  ulibrpc
//
//  Created by Andreas Fink on 20.08.2026.
//

#import <ulib/UMASN1Sequence.h>

/* callbacks should have the syntax
- (NSNumber *)someselectorname:(UMRpcMessage *)msg session:(UMRpcSession *)session
 */
@interface UMRpcSessionHandler : UMObject
{
    NSInteger   _sessionId;
    NSObject    *_objectToCall;
    SEL         _selectorToCall;
    id          _objectToAdd;    
}

@property (readwrite,assign)  NSInteger   sessionId;
@property (readwrite,strong)  NSObject    *objectToCall;
@property (readwrite,assign)  SEL         selectorToCall;
@property (readwrite,strong)  id          objectToAdd;

@end

