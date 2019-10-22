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
    BOOL _useJavaScriptKeyNames;
}

@property (nonatomic, strong) UMJsonStreamWriterState *state;
@property (nonatomic, readonly, strong) NSMutableArray *stateStack;
@property (unsafe_unretained) id<UMJsonStreamWriterDelegate> delegate;
@property NSUInteger maxDepth;
@property BOOL humanReadable;
@property BOOL sortKeys;
@property (readwrite,assign) SEL sortKeysSelector;
@property (readwrite,strong) NSString *error;
@property (readwrite,assign) BOOL useJavaScriptKeyNames; /* if set, will not put quotes around the key */

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
- (BOOL)writeKeyName:(NSString*)string;
@end

@interface UMJsonStreamWriter (Private)
- (BOOL)writeValue:(id)v;
- (void)appendBytes:(const void *)bytes length:(NSUInteger)length;
@end

#endif

