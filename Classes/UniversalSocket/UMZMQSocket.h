//
//  UMZMQSocket.h
//  smpprelay
//
//  Created by Andreas Fink on 12.07.22.
//


#import "UMObject.h"
#import "UMLogLevel.h"

@interface UMZMQSocket : UMObject
{
    NSString        *_socketName;
    void            *_context;
    void            *_socket;
    NSString        *_lastError;
    UMLogLevel      _logLevel;
}

@property(readwrite,strong,atomic) NSString *socketName;
@property(readwrite,strong,atomic) NSString *lastError;
@property(readwrite,assign,atomic) UMLogLevel logLevel;

- (UMZMQSocket *)initWithType:(int)type;
- (int)bind:(NSString *)name;
- (int)connect:(NSString *)name;
- (NSArray *)receiveArray;
- (int)sendArray:(NSArray *)arr;


- (int)sendData:(NSData *)d more:(BOOL)hasMore;
- (int)sendData:(NSData *)d;
- (NSData *)receiveData;
- (NSData *)receiveDataAndMore:(BOOL *)more;


- (int)sendString:(NSString *)d more:(BOOL)hasMore;
- (int)sendString:(NSString *)s;
- (NSString *)receiveString;
- (NSString *)receiveStringAndMore:(BOOL *)more;

- (int)sendUInt32:(uint32_t)i more:(BOOL)hasMore;
- (int)sendUInt32:(uint32_t)i;
- (uint32_t)receiveUInt32;
- (uint32_t)receiveUInt32AndMore:(BOOL *)more;


- (void)close;
@end


