//
//  UMZMQSocket.h
//  smpprelay
//
//  Created by Andreas Fink on 12.07.22.
//

#import "UMObject.h"

@interface UMZMQSocket : UMObject
{
    NSString *_socketName;
    void *_context;
    void *_socket;
    NSString *_lastError;
}

@property(readwrite,strong,atomic) NSString *socketName;
@property(readwrite,strong,atomic) NSString *lastError;

- (UMZMQSocket *)initWithType:(int)type;
- (int)bind:(NSString *)name;
- (int)connect:(NSString *)name;
- (NSArray *)receiveArray;
- (int)sendArray:(NSArray *)arr;
- (void)close;
@end

