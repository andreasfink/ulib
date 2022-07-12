//
//  UMZMQSocket.m
//  smpprelay
//
//  Created by Andreas Fink on 12.07.22.
//

#import "UMZMQSocket.h"
#if defined(HAVE_ZEROMQ)
#import <zmq.h>
#endif

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
                    rc = zmq_msg_send(&msg,socket,ZMQ_SNDMORE);
                }
                else
                {
                    rc = zmq_msg_send(&msg,socket,0);
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

- (void) close
{
#if defined(HAVE_ZEROMQ)
    zmq_ctx_destroy(_context);
#else
    [self setError:EOPNOTSUPP];
#endif
}
@end
