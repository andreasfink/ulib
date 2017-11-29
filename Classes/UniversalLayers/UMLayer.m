//
//  UMLayer.m
//  ulib.framework
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.

#import "UMLayer.h"

#import "UMThroughputCounter.h"
#import "UMTask.h"
#import "UMTaskQueue.h"
#import "UMTaskQueueMulti.h"
#import "UMAssert.h"
#import "UMLogFeed.h"
#import "UMLayerTask.h"
#import "UMLayerUserProtocol.h"
#import "NSString+UniversalObject.h"

@implementation UMLayer

@synthesize taskQueue;
@synthesize isSharedQueue;

@synthesize lowerQueueThroughput;
@synthesize upperQueueThroughput;
@synthesize adminQueueThroughput;

@synthesize layerName;
@synthesize layerType;
@synthesize enable;

@synthesize layerHistory;

@synthesize logLevel;

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
    [taskQueue queueTask:job toQueueNumber:UMLAYER_LOWER_QUEUE];
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
    [taskQueue queueTask:job toQueueNumber:UMLAYER_UPPER_QUEUE];
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
    [taskQueue queueTask:job toQueueNumber:UMLAYER_LOWER_PRIORITY_QUEUE];
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
    [taskQueue queueTask:job toQueueNumber:UMLAYER_UPPER_PRIORITY_QUEUE];
}

- (void)queueFromAdmin:(UMLayerTask *)job
{
    if(job.sender.logLevel <= UMLOG_DEBUG)
    {
        [job.sender.logFeed debug:0
                     inSubsection:@"txadmin"
                         withText:job.name];
    }
    [taskQueue queueTask:job toQueueNumber:UMLAYER_ADMIN_QUEUE];
}


- (UMLayer *)init
{
    return [self initWithTaskQueueMulti:NULL];
}

- (UMLayer *)initWithTaskQueueMulti:(UMTaskQueueMulti *)tq
{
    self = [super init];
    if(self)
    {
        if(tq == NULL)
        {
            UMTaskQueueMulti *tq =[[UMTaskQueueMulti alloc]initWithNumberOfThreads:4
                                                                              name:@"private_task_queue"
                                                                     enableLogging:NO
                                                                    numberOfQueues:UMLAYER_QUEUE_COUNT];
            taskQueue =tq;
            isSharedQueue = NO;
        }
        else
        {
            taskQueue =tq;
            isSharedQueue = YES;
        }
        lowerQueueThroughput = [[UMThroughputCounter alloc]init];
        upperQueueThroughput = [[UMThroughputCounter alloc]init];
        adminQueueThroughput = [[UMThroughputCounter alloc]init];
        logLevel = UMLOG_MAJOR;
    }
    return self;
}

- (void)logDebug:(NSString *)s
{
    [logFeed debugText:s];
}

- (void)logWarning:(NSString *)s
{
    [logFeed warningText:s];
}

- (void)logInfo:(NSString *)s
{
    [logFeed infoText:s];
}

- (void) logPanic:(NSString *)s
{
    [logFeed panicText:s];
}

- (void)logMajorError:(NSString *)s
{
    [logFeed majorErrorText:s];
}

- (void)logMinorError:(NSString *)s
{
    [logFeed majorErrorText:s];
}

- (void)logMajorError:(int)err location:(NSString *)location
{
    switch(err)
    {
        case 0:
            return;
            
        case EPROTONOSUPPORT:
            [logFeed majorErrorText:[NSString stringWithFormat:@"%@ EPROTONOSUPPORT: The protocol type or the specified protocol is not supported within this domain.",location]];
            break;
        case EMFILE:
            [logFeed majorErrorText:[NSString stringWithFormat:@"%@ EMFILE: The per-process descriptor table is full.",location]];
            break;
            
        case ENFILE:
            [logFeed majorErrorText:[NSString stringWithFormat:@"%@ ENFILE: The system file table is full.",location]];
            break;
        case EBADF:
            [logFeed majorErrorText:[NSString stringWithFormat:@"%@ EBADF: An invalid descriptor was specified",location]];
            break;
        case ENOTSOCK:
            [logFeed majorErrorText:[NSString stringWithFormat:@"%@ ENOTSOCK: The argument s is not a socket",location]];
            break;
        case EFAULT:
            [logFeed majorErrorText:[NSString stringWithFormat:@"%@ EFAULT:  An invalid  address or parameter was specified",location]];
            break;
        case EMSGSIZE:
            [logFeed majorErrorText:[NSString stringWithFormat:@"%@ EMSGSIZE: The socket requires that message be sent atomically, and the size of the message to be sent made this impossible.",location]];
            break;
        case EAGAIN:
            [logFeed majorErrorText:[NSString stringWithFormat:@"%@ EAGAIN: The socket is marked non-blocking and the requested operation would block.",location]];
            break;
        case ENOBUFS:
            [logFeed majorErrorText:[NSString stringWithFormat:@"%@ ENOBUFS: Insufficient buffer space is available",location]];
            break;
        case EACCES:
            [logFeed majorErrorText:[NSString stringWithFormat:@"%@ EACCES: Permission to create/use a socket of the specified type and/or protocol is denied.",location]];
            break;
        case EHOSTUNREACH:
            [logFeed majorErrorText:[NSString stringWithFormat:@"%@ EHOSTUNREACH The destination address specified an unreachable host.",location]];
            break;
        case EADDRNOTAVAIL:
            [logFeed majorErrorText:[NSString stringWithFormat:@"%@ EADDRNOTAVAIL The specified address is not available from the local machine.",location]];
            break;
        case EADDRINUSE:
            [logFeed majorErrorText:[NSString stringWithFormat:@"%@ EADDRINUSE The specified address is already in use.",location]];
            break;
        case EINVAL:
            [logFeed majorErrorText:[NSString stringWithFormat:@"%@ EINVAL The socket is already bound to an address. in bind(): The addrlen is wrong, or the socket was not in the AF_UNIX family",location]];
            break;
        case ENOTDIR:
            [logFeed majorErrorText:[NSString stringWithFormat:@"%@ ENOTDIR A component of the path prefix is not a directory.",location]];
            break;
        case ENAMETOOLONG:
            [logFeed majorErrorText:[NSString stringWithFormat:@"%@  ENAMETOOLONG a part of the pathname or the pathname itself is too long",location]];
            break;
        case ENOENT:
            [logFeed majorErrorText:[NSString stringWithFormat:@"%@ ENOENT A prefix component of the path name does not exist",location]];
            break;
        case ELOOP:
            [logFeed majorErrorText:[NSString stringWithFormat:@"%@ ELOOP Too many symbolic links were encountered in translating the pathname",location]];
            break;
        case EIO:
            [logFeed majorErrorText:[NSString stringWithFormat:@"%@ EIO An I/O error occurred while making the directory entry or allocating the inode.",location]];
            break;
        case EROFS:
            [logFeed majorErrorText:[NSString stringWithFormat:@"%@ EROFS The name would reside on a read-only file system.",location]];
            break;
        case EISDIR:
            [logFeed majorErrorText:[NSString stringWithFormat:@"%@ EISDIR An empty pathname was specified.",location]];
            break;
        case EPFNOSUPPORT:
            [logFeed majorErrorText:[NSString stringWithFormat:@"%@ EPFNOSUPPORT Protocol family not supported",location]];
            break;
        case EAFNOSUPPORT:
            [logFeed majorErrorText:[NSString stringWithFormat:@"%@ EAFNOSUPPORT  Address family not supported by protocol family ",location]];
            break;
        case ECONNRESET:
            [logFeed majorErrorText:[NSString stringWithFormat:@"%@ ECONNRESET Connection reset by peer",location]];
            break;
        default:
            [logFeed majorErrorText:[NSString stringWithFormat:@"%@ error %d",location,err]];
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
            
        case EPROTONOSUPPORT:
            [logFeed minorErrorText:[NSString stringWithFormat:@"%@ EPROTONOSUPPORT: The protocol type or the specified protocol is not supported within this domain.",location]];
            break;
        case EMFILE:
            [logFeed minorErrorText:[NSString stringWithFormat:@"%@ EMFILE: The per-process descriptor table is full.",location]];
            break;
            
        case ENFILE:
            [logFeed minorErrorText:[NSString stringWithFormat:@"%@ ENFILE: The system file table is full.",location]];
            break;
        case EBADF:
            [logFeed minorErrorText:[NSString stringWithFormat:@"%@ EBADF: An invalid descriptor was specified",location]];
            break;
        case ENOTSOCK:
            [logFeed minorErrorText:[NSString stringWithFormat:@"%@ ENOTSOCK: The argument s is not a socket",location]];
            break;
        case EFAULT:
            [logFeed minorErrorText:[NSString stringWithFormat:@"%@ EFAULT:  An invalid  address or parameter was specified",location]];
            break;
        case EMSGSIZE:
            [logFeed minorErrorText:[NSString stringWithFormat:@"%@ EMSGSIZE: The socket requires that message be sent atomically, and the size of the message to be sent made this impossible.",location]];
            break;
        case EAGAIN:
            [logFeed minorErrorText:[NSString stringWithFormat:@"%@ EAGAIN: The socket is marked non-blocking and the requested operation would block.",location]];
            break;
        case ENOBUFS:
            [logFeed minorErrorText:[NSString stringWithFormat:@"%@ ENOBUFS: Insufficient buffer space is available",location]];
            break;
        case EACCES:
            [logFeed minorErrorText:[NSString stringWithFormat:@"%@ EACCES: Permission to create/use a socket of the specified type and/or protocol is denied.",location]];
            break;
        case EHOSTUNREACH:
            [logFeed minorErrorText:[NSString stringWithFormat:@"%@ EHOSTUNREACH The destination address specified an unreachable host.",location]];
            break;
        case EADDRNOTAVAIL:
            [logFeed minorErrorText:[NSString stringWithFormat:@"%@ EADDRNOTAVAIL The specified address is not available from the local machine..",location]];
            break;
        case EADDRINUSE:
            [logFeed minorErrorText:[NSString stringWithFormat:@"%@ EADDRINUSE The specified address is already in use.",location]];
            break;
        case EINVAL:
            [logFeed minorErrorText:[NSString stringWithFormat:@"%@ EINVAL The socket is already bound to an address. in bind(): The addrlen is wrong, or the socket was not in the AF_UNIX family",location]];
            break;
        case ENOTDIR:
            [logFeed minorErrorText:[NSString stringWithFormat:@"%@ ENOTDIR A component of the path prefix is not a directory.",location]];
            break;
        case ENAMETOOLONG:
            [logFeed minorErrorText:[NSString stringWithFormat:@"%@  ENAMETOOLONG a part of the pathname or the pathname itself is too long",location]];
            break;
        case ENOENT:
            [logFeed minorErrorText:[NSString stringWithFormat:@"%@ ENOENT A prefix component of the path name does not exist",location]];
            break;
        case ELOOP:
            [logFeed minorErrorText:[NSString stringWithFormat:@"%@ ELOOP Too many symbolic links were encountered in translating the pathname",location]];
            break;
        case EIO:
            [logFeed minorErrorText:[NSString stringWithFormat:@"%@ EIO An I/O error occurred while making the directory entry or allocating the inode.",location]];
            break;
        case EROFS:
            [logFeed minorErrorText:[NSString stringWithFormat:@"%@ EROFS The name would reside on a read-only file system.",location]];
            break;
        case EISDIR:
            [logFeed minorErrorText:[NSString stringWithFormat:@"%@ EISDIR An empty pathname was specified.",location]];
            break;
        case EPFNOSUPPORT:
            [logFeed minorErrorText:[NSString stringWithFormat:@"%@ EPFNOSUPPORT Protocol family not supported",location]];
            break;
        case EAFNOSUPPORT:
            [logFeed minorErrorText:[NSString stringWithFormat:@"%@ EAFNOSUPPORT  Address family not supported by protocol family ",location]];
            break;
        case ECONNRESET:
            [logFeed minorErrorText:[NSString stringWithFormat:@"%@ ECONNRESET Connection reset by peer",location]];
            break;
        default:
            [logFeed minorErrorText:[NSString stringWithFormat:@"%@ error %d",location,err]];
            break;
    }
}

- (void)adminInit
{
    [logFeed majorErrorText:@"adminInit not implemented"];
}

- (void)adminAttachFor:(id)attachingUser userId:(id)uid
{
    [logFeed majorErrorText:@"adminAttachFor not implemented"];
}

- (void)adminAttachConfirm:(UMLayer *)reportingLayer userId:(id)uid
{
    [logFeed majorErrorText:@"adminAttachConfirm not implemented"];
}

- (void)adminAttachFail:(UMLayer *)reportingLayer userId:(id)uid
{
    [logFeed majorErrorText:@"adminAttachFail not implemented"];
}


- (void)addLayerConfig:(NSMutableDictionary *)config
{
    config[@"name"] = self.layerName;
    config[@"enable"]=  enable ? @YES : @NO;
    config[@"log-level"]=@(logLevel);
    /* we should add some log file options here somehow */
}

- (void)readLayerConfig:(NSDictionary *)cfg
{
    if(cfg[@"name"])
    {
        layerName = [cfg[@"name"]stringValue];
    }
    if(cfg[@"enable"])
    {
        enable = [cfg[@"enable"]boolValue];
    }

    if(cfg[@"log-level"])
    {
        logLevel = [cfg[@"log-level"]intValue];
    }
}

@end
