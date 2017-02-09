//
//  UMJSonStreamWriterState.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "UMObject.h"

@class UMJsonStreamWriter;

@interface UMJsonStreamWriterState : UMObject
+ (id)sharedInstance;
- (BOOL)isInvalidState:(UMJsonStreamWriter*)writer;
- (void)appendSeparator:(UMJsonStreamWriter*)writer;
- (BOOL)expectingKey:(UMJsonStreamWriter*)writer;
- (void)transitionState:(UMJsonStreamWriter*)writer;
- (void)appendWhitespace:(UMJsonStreamWriter*)writer;
@end

@interface UMJsonStreamWriterStateObjectStart : UMJsonStreamWriterState
@end

@interface UMJsonStreamWriterStateObjectKey : UMJsonStreamWriterStateObjectStart
@end

@interface UMJsonStreamWriterStateObjectValue : UMJsonStreamWriterState
@end

@interface UMJsonStreamWriterStateArrayStart : UMJsonStreamWriterState
@end

@interface UMJsonStreamWriterStateArrayValue : UMJsonStreamWriterState
@end

@interface UMJsonStreamWriterStateStart : UMJsonStreamWriterState
@end

@interface UMJsonStreamWriterStateComplete : UMJsonStreamWriterState
@end

@interface UMJsonStreamWriterStateError : UMJsonStreamWriterState
@end

