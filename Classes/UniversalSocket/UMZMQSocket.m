//
//  UMZMQSocket.m
//  smpprelay
//
//  Created by Andreas Fink on 12.07.22.
//

#import "UMZMQSocket.h"
#import "ulib_config.h"

#if defined(HAVE_ZMQ_H)
#include <zmq.h>
#define HAVE_ZEROMQ 1
#endif

#import "NSData+UniversalObject.h"

@implementation UMZMQSocket

- (UMZMQSocket *)initWithType:(int)type
{
    self = [super init];
    if(self)
    {
#if defined(HAVE_ZEROMQ)
        _context = zmq_ctx_new();
        _socket = zmq_socket(_context,type);
#endif
    }
    return self;
}

-(void)clearError
{
    _lastError=@"";
}

-(void)setError:(int)err
{
    if(err==0)
    {
        _lastError=@"";
    }
    else
    {
        _lastError = @(strerror(err));
    }
}


- (int)bind:(NSString *)name
{
#if defined(HAVE_ZEROMQ)
    int rc = zmq_bind(_socket,name.UTF8String);
    if(rc!=0)
    {
        [self setError:errno];
    }
    else
    {
        [self clearError];
    }
    return rc;
#else
    [self setError:EOPNOTSUPP];
    return EOPNOTSUPP;
#endif
}

- (int)connect:(NSString *)name
{
#if defined(HAVE_ZEROMQ)
    int rc = zmq_connect(_socket,name.UTF8String);
    if(rc!=0)
    {
        [self setError:errno];
    }
    else
    {
        [self clearError];
    }
    return rc;
#else
    [self setError:EOPNOTSUPP];
    return EOPNOTSUPP;
#endif
}


- (void) close
{
#if defined(HAVE_ZEROMQ)
    zmq_ctx_destroy(_context);
#else
    [self setError:EOPNOTSUPP];
#endif
}

#pragma mark -

- (NSArray *)receiveArray
{
#if defined(HAVE_ZEROMQ)
    int more = 1;
    NSMutableArray *arr = [[NSMutableArray alloc]init];

    while(more)
    {
        zmq_msg_t msg;
        zmq_msg_init(&msg);
        int rc = zmq_msg_recv(&msg,_socket,0);
        if(rc==-1)
        {
            [self setError:errno];
            more = 0;
        }
        else
        {
            [self clearError];
            size_t len = zmq_msg_size(&msg);
            void *ptr = zmq_msg_data(&msg);
            NSData *data = [NSData dataWithBytes:ptr length:len];
            [arr addObject:data];
            more = zmq_msg_more(&msg);
        }
        zmq_msg_close(&msg);
    }
    return arr;
#else
    sleep(1);
    // avoid busyloops if backgrounder is
    // started without support
    [self setError:EOPNOTSUPP];
    return NULL;
#endif
}




- (int)sendArray:(NSArray *)arr
{
#if defined(HAVE_ZEROMQ)
    int rc=0;
    int remaining = (int)arr.count;
    for(id obj in arr)
    {
        NSData *d;
        if([obj isKindOfClass:[NSData class]])
        {
            d = (NSData *)d;
        }
        else if([obj isKindOfClass:[NSString class]])
        {
            NSString *s = (NSString *)obj;
            d = [s dataUsingEncoding:NSUTF8StringEncoding];
        }
        else
        {
            d = [NSData data];
        }
        remaining--;
        if(remaining == 0)
        {
            zmq_msg_t msg;
            rc = zmq_msg_init_size(&msg,d.length);
            if(rc==0)
            {
                memcpy(zmq_msg_data(&msg),d.bytes,d.length);
                if(remaining>0)
                {
                    rc = zmq_msg_send(&msg,_socket,ZMQ_SNDMORE);
                }
                else
                {
                    rc = zmq_msg_send(&msg,_socket,0);
                }
                if(rc!=0)
                {
                    [self setError:errno];
                }
                else
                {
                    [self clearError];
                }
            }
            zmq_msg_close(&msg);
        }
    }
    return rc;
#else
    [self setError:EOPNOTSUPP];
    return -1;
#endif
}


#pragma mark -
- (int)sendData:(NSData *)d more:(BOOL)hasMore
{
#if defined(HAVE_ZEROMQ)
    zmq_msg_t msg;
    int rc = zmq_msg_init_size(&msg,d.length);
    if(rc==0)
    {
        memcpy(zmq_msg_data(&msg),d.bytes,d.length);
        if(hasMore)
        {
            rc = zmq_msg_send(&msg,_socket,ZMQ_SNDMORE);
        }
        else
        {
            rc = zmq_msg_send(&msg,_socket,0);
        }
        if(rc!=0)
        {
            [self setError:errno];
        }
        else
        {
            [self clearError];
        }
    }
    zmq_msg_close(&msg);
    return rc;
#else
    [self setError:EOPNOTSUPP];
    return -1;
#endif
}

- (int)sendData:(NSData *)d
{
    return [self sendData:d more:NO];
}

- (NSData *)receiveData
{
    BOOL more;
    return [self receiveDataAndMore:&more];
}

- (NSData *)receiveDataAndMore:(BOOL *)morePtr
{
#if defined(HAVE_ZEROMQ)
    NSData *returnData = NULL;
    zmq_msg_t msg;
    zmq_msg_init(&msg);
    int rc = zmq_msg_recv(&msg,_socket,0);
    if(rc==-1)
    {
        [self setError:errno];
        if(morePtr)
        {
            *morePtr = 0;
        }
    }
    else
    {
        [self clearError];
        size_t len = zmq_msg_size(&msg);
        void *ptr = zmq_msg_data(&msg);
        returnData = [NSData dataWithBytes:ptr length:len];
        if(morePtr)
        {
            *morePtr = zmq_msg_more(&msg);
        }
    }
    zmq_msg_close(&msg);
    return returnData;
#else
    usleep(100000);
    // avoid busyloops if backgrounder is
    // started without support
    [self setError:EOPNOTSUPP];
    return NULL;
#endif
}
#pragma mark -

- (int)sendString:(NSString *)s more:(BOOL)hasMore
{
    NSData *d = [s dataUsingEncoding:NSUTF8StringEncoding];
    return [self sendData:d more:hasMore];
}

- (int)sendString:(NSString *)s
{
    return [self sendString:s more:NO];
}

- (NSString *)receiveString
{
    BOOL more;
    return [self receiveStringAndMore:&more];
}


- (NSString *)receiveStringAndMore:(BOOL *)more
{
    NSData *d = [self receiveDataAndMore:more];
    NSString *s = [d utf8String];
    return s;
}

#pragma mark -

- (int)sendUInt32:(uint32_t)i more:(BOOL)hasMore
{
    uint8_t bytes[4];
    bytes[0] = (i >> 24) & 0xFF;
    bytes[1] = (i >> 16) & 0xFF;
    bytes[2] = (i >> 8) & 0xFF;
    bytes[3] = (i >> 0) & 0xFF;
    NSData *d = [NSData dataWithBytes:&bytes length:4];
    return [self sendData:d more:hasMore];
}

- (int)sendUInt32:(uint32_t)i
{
    return [self sendUInt32:i more:NO];
}

- (uint32_t)receiveUInt32
{
    BOOL more;
    return [self receiveUInt32AndMore:&more];
}

- (uint32_t)receiveUInt32AndMore:(BOOL *)more
{
    uint32_t result = 0;
    NSData *d = [self receiveDataAndMore:more];
    if(d.length == 4)
    {
        const uint8_t *bytes = d.bytes;
        result  = (bytes[0] << 24);
        result |= (bytes[1] << 16);
        result |= (bytes[2] << 8);
        result |= (bytes[3] << 0);
    }
    return result;
}

@end
