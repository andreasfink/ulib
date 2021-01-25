//
//  UMLayer.m
//  ulib.framework
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.

#import "UMLayer.h"

#import "UMThroughputCounter.h"
#import "UMTaskQueueTask.h"
#import "UMTaskQueue.h"
#import "UMTaskQueueMulti.h"
#import "UMAssert.h"
#import "UMLogFeed.h"
#import "UMLayerTask.h"
#import "UMLayerUserProtocol.h"
#import "NSString+UniversalObject.h"
#import "UMAssert.h"

#if defined(FREEBSD)
/* we need to get non posix error codes included */
#if defined(_POSIX_SOURCE)
#undef _POSIX_SOURCE
#endif
#include <errno.h>
#include <sys/errno.h>
#endif

@implementation UMLayer

- (void)queueFromLower:(UMLayerTask *)job
{
    if(job==NULL)
    {
        return;
    }
    /* we log to the sending task that it send it.
     the receiving log is before executing it */
    if(job.sender.logLevel <= UMLOG_DEBUG)
    {
        [job.sender.logFeed debug:0
                     inSubsection:@"txup"
                         withText:job.name];
    }
    UMAssert(_taskQueue !=NULL,@"Can not queue task to NULL queue");
    [_taskQueue queueTask:job toQueueNumber:UMLAYER_LOWER_QUEUE];
}

- (void)queueFromUpper:(UMLayerTask *)job
{
    if(job==NULL)
    {
        return;
    }
    if(job.sender.logLevel <= UMLOG_DEBUG)
    {

        [job.sender.logFeed debug:0
                     inSubsection:@"txdown"
                         withText:job.name];
    }
    UMAssert(_taskQueue !=NULL,@"Can not queue task to NULL queue");
    [_taskQueue queueTask:job toQueueNumber:UMLAYER_UPPER_QUEUE];
}

- (void)queueFromLowerWithPriority:(UMLayerTask *)job
{
    if(job==NULL)
    {
        return;
    }

    /* we log to the sending task that it send it.
     the receiving log is before executing it */
    if(job.sender.logLevel <= UMLOG_DEBUG)
    {
        [job.sender.logFeed debug:0
                     inSubsection:@"txup"
                         withText:job.name];
    }
    UMAssert(_taskQueue !=NULL,@"Can not queue task to NULL queue");
    [_taskQueue queueTask:job toQueueNumber:UMLAYER_LOWER_PRIORITY_QUEUE];
}

- (void)queueFromUpperWithPriority:(UMLayerTask *)job
{
    if(job==NULL)
    {
        return;
    }
    if(job.sender.logLevel <= UMLOG_DEBUG)
    {
        [job.sender.logFeed debug:0
                     inSubsection:@"txdown"
                         withText:job.name];
    }
    UMAssert(_taskQueue !=NULL,@"Can not queue task to NULL queue");
    [_taskQueue queueTask:job toQueueNumber:UMLAYER_UPPER_PRIORITY_QUEUE];
}

- (void)queueFromAdmin:(UMLayerTask *)job
{
    if(job.sender.logLevel <= UMLOG_DEBUG)
    {
        [job.sender.logFeed debug:0
                     inSubsection:@"txadmin"
                         withText:job.name];
    }
    UMAssert(_taskQueue !=NULL,@"Can not queue task to NULL queue");
    [_taskQueue queueTask:job toQueueNumber:UMLAYER_ADMIN_QUEUE];
}


- (void)queueMultiFromAdmin:(NSArray<UMLayerTask *>*)job
{
    [_taskQueue queueArrayOfTasks:job toQueueNumber:UMLAYER_ADMIN_QUEUE];
}

- (void)queueMultiFromLower:(NSArray<UMLayerTask *>*)job
{
    [_taskQueue queueArrayOfTasks:job toQueueNumber:UMLAYER_LOWER_QUEUE];
}

- (void)queueMultiFromUpper:(NSArray<UMLayerTask *>*)job
{
    [_taskQueue queueArrayOfTasks:job toQueueNumber:UMLAYER_UPPER_QUEUE];
}

- (UMLayer *)init
{
    return [self initWithTaskQueueMulti:NULL];
}

- (UMLayer *)initWithTaskQueueMulti:(UMTaskQueueMulti *)tq
{
    return [self initWithTaskQueueMulti:tq name:@""];
}

- (UMLayer *)initWithTaskQueueMulti:(UMTaskQueueMulti *)tq
                               name:(NSString *)name
{
    self = [super init];
    if(self)
    {
        _layerName = name;

        if(tq == NULL)
        {
            NSString *s = (name.length > 0) ? [NSString stringWithFormat:@"private_task_queue(%@)",name] : @"private_task_queue";
            UMTaskQueueMulti *tq =[[UMTaskQueueMulti alloc]initWithNumberOfThreads:4
                                                                              name:s
                                                                     enableLogging:NO
                                                                    numberOfQueues:UMLAYER_QUEUE_COUNT];
            _taskQueue =tq;
            _isSharedQueue = NO;
        }
        else
        {
            _taskQueue =tq;
            _isSharedQueue = YES;
        }
        _lowerQueueThroughput = [[UMThroughputCounter alloc]initWithResolutionInSeconds: 1.0 maxDuration: 1260.0];
        _upperQueueThroughput = [[UMThroughputCounter alloc]initWithResolutionInSeconds: 1.0 maxDuration: 1260.0];
        _adminQueueThroughput = [[UMThroughputCounter alloc]initWithResolutionInSeconds: 1.0 maxDuration: 1260.0];
        _logLevel = UMLOG_MAJOR;
    }
    return self;
}

- (void)logDebug:(NSString *)s
{
    [self.logFeed debugText:s];
}

- (void)logWarning:(NSString *)s
{
    [self.logFeed warningText:s];
}

- (void)logInfo:(NSString *)s
{
    [self.logFeed infoText:s];
}

- (void) logPanic:(NSString *)s
{
    [self.logFeed panicText:s];
}

- (void)logMajorError:(NSString *)s
{
    [self.logFeed majorErrorText:s];
}

- (void)logMinorError:(NSString *)s
{
    [self.logFeed majorErrorText:s];
}

- (void)logMajorError:(int)err location:(NSString *)location
{
    switch(err)
    {
        case 0:
            return;

#if defined(EPROTONOSUPPORT)
        case EPROTONOSUPPORT:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ EPROTONOSUPPORT: The protocol type or the specified protocol is not supported within this domain.",location]];
            break;
#endif
#if defined(EMFILE)
        case EMFILE:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ EMFILE: The per-process descriptor table is full.",location]];
            break;
#endif
#if defined(ENFILE)
        case ENFILE:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ ENFILE: The system file table is full.",location]];
            break;
#endif
#if defined(EBADF)
        case EBADF:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ EBADF: An invalid descriptor was specified",location]];
            break;
#endif
#if defined(ENOTSOCK)
        case ENOTSOCK:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ ENOTSOCK: The argument s is not a socket",location]];
            break;
#endif
#if defined(EFAULT)
        case EFAULT:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ EFAULT:  An invalid  address or parameter was specified",location]];
            break;
#endif
#if defined(EMSGSIZE)
        case EMSGSIZE:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ EMSGSIZE: The socket requires that message be sent atomically, and the size of the message to be sent made this impossible.",location]];
            break;
#endif
#if defined(EAGAIN)
        case EAGAIN:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ EAGAIN: The socket is marked non-blocking and the requested operation would block.",location]];
            break;
#endif
#if defined(ENOBUFS)
        case ENOBUFS:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ ENOBUFS: Insufficient buffer space is available",location]];
            break;
#endif
#if defined(EACCESS)
        case EACCES:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ EACCES: Permission to create/use a socket of the specified type and/or protocol is denied.",location]];
            break;
#endif
#if defined(EHOSTUNREACH)
        case EHOSTUNREACH:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ EHOSTUNREACH The destination address specified an unreachable host.",location]];
            break;
#endif
#if defined(EADDRNOTAVAIL)
        case EADDRNOTAVAIL:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ EADDRNOTAVAIL The specified address is not available from the local machine.",location]];
            break;
#endif
#if defined(EADDRINUSE)
        case EADDRINUSE:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ EADDRINUSE The specified address is already in use.",location]];
            break;
#endif
#if defined(EINVAL)
        case EINVAL:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ EINVAL The socket is already bound to an address. in bind(): The addrlen is wrong, or the socket was not in the AF_UNIX family",location]];
            break;
#endif
#if defined(ENOTDIR)
        case ENOTDIR:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ ENOTDIR A component of the path prefix is not a directory.",location]];
            break;
#endif
#if defined(ENAMETOOLONG)
        case ENAMETOOLONG:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@  ENAMETOOLONG a part of the pathname or the pathname itself is too long",location]];
            break;
#endif
#if defined(ENOENT)
        case ENOENT:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ ENOENT A prefix component of the path name does not exist",location]];
            break;
#endif
#if defined(ELOOP)
        case ELOOP:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ ELOOP Too many symbolic links were encountered in translating the pathname",location]];
            break;
#endif
#if defined(EIO)
        case EIO:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ EIO An I/O error occurred while making the directory entry or allocating the inode.",location]];
            break;
#endif
#if defined(EROFS)
        case EROFS:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ EROFS The name would reside on a read-only file system.",location]];
            break;
#endif
#if defined(EISDIR)
        case EISDIR:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ EISDIR An empty pathname was specified.",location]];
            break;
#endif
#if defined(EPFNOSUPPORT)
        case EPFNOSUPPORT:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ EPFNOSUPPORT Protocol family not supported",location]];
            break;
#endif
#if defined(EAFNOSUPPORT)
        case EAFNOSUPPORT:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ EAFNOSUPPORT  Address family not supported by protocol family ",location]];
            break;
#endif
#if defined(ECONNRESET)
        case ECONNRESET:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ ECONNRESET Connection reset by peer",location]];
            break;
#endif
        default:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ error %d",location,err]];
            break;
    }
}

- (void)logWarning:(int)err location:(NSString *)location
{
    
}
- (void)logMinorError:(int)err location:(NSString *)location
{
    switch(err)
    {
        case 0:
            return;

#if defined(EPROTONOSUPPORT)
        case EPROTONOSUPPORT:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ EPROTONOSUPPORT: The protocol type or the specified protocol is not supported within this domain.",location]];
            break;
#endif
#if defined(EMFILE)
        case EMFILE:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ EMFILE: The per-process descriptor table is full.",location]];
            break;
#endif
#if defined(ENFILE)
        case ENFILE:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ ENFILE: The system file table is full.",location]];
            break;
#endif
#if defined(EBADF)
        case EBADF:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ EBADF: An invalid descriptor was specified",location]];
            break;
#endif
#if defined(ENOTSOCK)
        case ENOTSOCK:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ ENOTSOCK: The argument s is not a socket",location]];
            break;
#endif
#if defined(EFAULT)
        case EFAULT:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ EFAULT:  An invalid  address or parameter was specified",location]];
            break;
#endif
#if defined(EMSGSIZE)
        case EMSGSIZE:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ EMSGSIZE: The socket requires that message be sent atomically, and the size of the message to be sent made this impossible.",location]];
            break;
#endif
        case EAGAIN:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ EAGAIN: The socket is marked non-blocking and the requested operation would block.",location]];
            break;
#if defined(ENOBUFS)
        case ENOBUFS:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ ENOBUFS: Insufficient buffer space is available",location]];
            break;
#endif
        case EACCES:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ EACCES: Permission to create/use a socket of the specified type and/or protocol is denied.",location]];
            break;
#if defined(EHOSTUNREACH)
        case EHOSTUNREACH:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ EHOSTUNREACH The destination address specified an unreachable host.",location]];
            break;
#endif
#if defined(EADDRNOTAVAIL)
        case EADDRNOTAVAIL:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ EADDRNOTAVAIL The specified address is not available from the local machine..",location]];
            break;
#endif
#if defined(EADDRINUSE)
        case EADDRINUSE:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ EADDRINUSE The specified address is already in use.",location]];
            break;
#endif
#if defined(EINVAL)
        case EINVAL:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ EINVAL The socket is already bound to an address. in bind(): The addrlen is wrong, or the socket was not in the AF_UNIX family",location]];
            break;
#endif
#if defined(ENOTDIR)
        case ENOTDIR:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ ENOTDIR A component of the path prefix is not a directory.",location]];
            break;
#endif
#if defined(ENAMETOOLONG)
        case ENAMETOOLONG:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@  ENAMETOOLONG a part of the pathname or the pathname itself is too long",location]];
            break;
#endif
#if defined(ENOENT)
        case ENOENT:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ ENOENT A prefix component of the path name does not exist",location]];
            break;
#endif
#if defined (ELOOP)
        case ELOOP:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ ELOOP Too many symbolic links were encountered in translating the pathname",location]];
            break;
#endif
#if defined(EIO)
        case EIO:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ EIO An I/O error occurred while making the directory entry or allocating the inode.",location]];
            break;
#endif
#if defined(EROFS)
        case EROFS:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ EROFS The name would reside on a read-only file system.",location]];
            break;
#endif
#if defined(EISDIR)
       case EISDIR:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ EISDIR An empty pathname was specified.",location]];
            break;
#endif
#if defined(EPFNOSUPPORT)
       case EPFNOSUPPORT:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ EPFNOSUPPORT Protocol family not supported",location]];
            break;
#endif
#if defined(EAFNOSUPPORT)
       case EAFNOSUPPORT:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ EAFNOSUPPORT  Address family not supported by protocol family ",location]];
            break;
#endif
#if defined(ECONNRESET)
       case ECONNRESET:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ ECONNRESET Connection reset by peer",location]];
            break;
#endif
        default:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ error %d",location,err]];
            break;
    }
}

- (void)adminInit
{
    [self.logFeed majorErrorText:@"adminInit not implemented"];
}

- (void)adminAttachFor:(id)attachingUser userId:(id)uid
{
    [self.logFeed majorErrorText:@"adminAttachFor not implemented"];
}

- (void)adminAttachConfirm:(UMLayer *)reportingLayer userId:(id)uid
{
    [self.logFeed majorErrorText:@"adminAttachConfirm not implemented"];
}

- (void)adminAttachFail:(UMLayer *)reportingLayer userId:(id)uid
{
    [self.logFeed majorErrorText:@"adminAttachFail not implemented"];
}


- (void)addLayerConfig:(NSMutableDictionary *)config
{
    config[@"name"] = self.layerName;
    config[@"enable"]=  _enable ? @YES : @NO;
    config[@"log-level"]=@(_logLevel);
    /* we should add some log file options here somehow */
}

- (void)readLayerConfig:(NSDictionary *)cfg
{
    if(cfg[@"name"])
    {
        _layerName = [cfg[@"name"]stringValue];
    }
    if(cfg[@"enable"])
    {
        _enable = [cfg[@"enable"]boolValue];
    }

    if(cfg[@"log-level"])
    {
        _logLevel = [cfg[@"log-level"]intValue];
    }
}

- (void)dump:(NSFileHandle *)filehandler
{
    NSMutableString *s = [[NSMutableString alloc]init];
    [s appendString:@"\n"];
    [s appendString:@"--------------------------------------------------------------------------------\n"];
    [s appendFormat:@"Layer: %@\n",_layerName];
    [s appendString:@"--------------------------------------------------------------------------------\n"];
    [filehandler writeData: [s dataUsingEncoding:NSUTF8StringEncoding]];
}
@end
