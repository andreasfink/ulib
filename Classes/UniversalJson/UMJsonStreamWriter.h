//
//  UMJSonStreamWriter.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#ifndef UMJsonStreamWriter_H
#define UMJsonStreamWriter_H 1


#import <Foundation/Foundation.h>
#import "UMObject.h"
#import "UMSynchronizedSortedDictionary.h"

@interface NSObject (UMProxyForJson)
- (id)proxyForJson;
@end

@class UMJsonStreamWriter;

@protocol UMJsonStreamWriterDelegate
- (void)writer:(UMJsonStreamWriter*)writer appendBytes:(const void *)bytes length:(NSUInteger)length;
@end

@class UMJsonStreamWriterState;
@interface UMJsonStreamWriter : UMObject
{
    NSMutableDictionary *cache;
    UMJsonStreamWriterState *state;
    NSMutableArray *stateStack;
    id<UMJsonStreamWriterDelegate> __unsafe_unretained delegate;
    NSUInteger maxDepth;
    BOOL humanReadable;
    BOOL sortKeys;
    SEL sortKeysSelector;
    NSString *error;

}

@property (nonatomic, strong) UMJsonStreamWriterState *state;
@property (nonatomic, readonly, strong) NSMutableArray *stateStack;
@property (unsafe_unretained) id<UMJsonStreamWriterDelegate> delegate;
@property NSUInteger maxDepth;
@property BOOL humanReadable;
@property BOOL sortKeys;
@property (readwrite,assign) SEL sortKeysSelector;
@property (readwrite,strong) NSString *error;

- (BOOL)writeObject:(NSDictionary*)dict;
- (BOOL)writeSortedDictionary:(UMSynchronizedSortedDictionary *)dict;
- (BOOL)writeArray:(NSArray *)array;
- (BOOL)writeObjectOpen;
- (BOOL)writeObjectClose;
- (BOOL)writeArrayOpen;
- (BOOL)writeArrayClose;
- (BOOL)writeNull;
- (BOOL)writeBool:(BOOL)x;
- (BOOL)writeNumber:(NSNumber*)n;
- (BOOL)writeString:(NSString*)s;
@end

@interface UMJsonStreamWriter (Private)
- (BOOL)writeValue:(id)v;
- (void)appendBytes:(const void *)bytes length:(NSUInteger)length;
@end

#endif

