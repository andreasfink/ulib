//
//  UMRpcCommandHandler.h
//  ulibrpc
//
//  Created by Andreas Fink on 20.08.2026.
//

#import <ulib/UMASN1Sequence.h>

@interface UMRpcCommandHandler : UMObject
{
    NSInteger   _command;
    NSString    *_name;
    NSObject    *_objectToCall;
    SEL         _selectorToCall;
}

@property (readwrite,assign)  NSInteger   command;
@property (readwrite,strong)  NSString    *name;
@property (readwrite,strong)  NSObject    *objectToCall;
@property (readwrite,assign)  SEL         selectorToCall;
@property (readwrite,strong)  NSObject    *decodeObjectToCall;
@property (readwrite,assign)  SEL         decodeSelectorToCall;

@end

