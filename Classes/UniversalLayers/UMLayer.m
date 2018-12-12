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
    return [self initWithTaskQueueMulti:tq name:@""];
}

- (UMLayer *)initWithTaskQueueMulti:(UMTaskQueueMulti *)tq name:(NSString *)name
{
    self = [super init];
    if(self)
    {
        layerName = name;
        if(tq == NULL)
        {
            NSString *s = (name.length > 0) ? [NSString stringWithFormat:@"private_task_queue(%@)",name] : @"private_task_queue";
            UMTaskQueueMulti *tq =[[UMTaskQueueMulti alloc]initWithNumberOfThreads:4
                                                                              name:s
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
        lowerQueueThroughput = [[UMThroughputCounter alloc]initWithResolutionInSeconds: 1.0 maxDuration: 1260.0];
        upperQueueThroughput = [[UMThroughputCounter alloc]initWithResolutionInSeconds: 1.0 maxDuration: 1260.0];
        adminQueueThroughput = [[UMThroughputCounter alloc]initWithResolutionInSeconds: 1.0 maxDuration: 1260.0];
        logLevel = UMLOG_MAJOR;
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
            
        case EPROTONOSUPPORT:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ EPROTONOSUPPORT: The protocol type or the specified protocol is not supported within this domain.",location]];
            break;
        case EMFILE:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ EMFILE: The per-process descriptor table is full.",location]];
            break;
            
        case ENFILE:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ ENFILE: The system file table is full.",location]];
            break;
        case EBADF:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ EBADF: An invalid descriptor was specified",location]];
            break;
        case ENOTSOCK:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ ENOTSOCK: The argument s is not a socket",location]];
            break;
        case EFAULT:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ EFAULT:  An invalid  address or parameter was specified",location]];
            break;
        case EMSGSIZE:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ EMSGSIZE: The socket requires that message be sent atomically, and the size of the message to be sent made this impossible.",location]];
            break;
        case EAGAIN:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ EAGAIN: The socket is marked non-blocking and the requested operation would block.",location]];
            break;
        case ENOBUFS:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ ENOBUFS: Insufficient buffer space is available",location]];
            break;
        case EACCES:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ EACCES: Permission to create/use a socket of the specified type and/or protocol is denied.",location]];
            break;
        case EHOSTUNREACH:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ EHOSTUNREACH The destination address specified an unreachable host.",location]];
            break;
        case EADDRNOTAVAIL:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ EADDRNOTAVAIL The specified address is not available from the local machine.",location]];
            break;
        case EADDRINUSE:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ EADDRINUSE The specified address is already in use.",location]];
            break;
        case EINVAL:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ EINVAL The socket is already bound to an address. in bind(): The addrlen is wrong, or the socket was not in the AF_UNIX family",location]];
            break;
        case ENOTDIR:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ ENOTDIR A component of the path prefix is not a directory.",location]];
            break;
        case ENAMETOOLONG:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@  ENAMETOOLONG a part of the pathname or the pathname itself is too long",location]];
            break;
        case ENOENT:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ ENOENT A prefix component of the path name does not exist",location]];
            break;
        case ELOOP:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ ELOOP Too many symbolic links were encountered in translating the pathname",location]];
            break;
        case EIO:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ EIO An I/O error occurred while making the directory entry or allocating the inode.",location]];
            break;
        case EROFS:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ EROFS The name would reside on a read-only file system.",location]];
            break;
        case EISDIR:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ EISDIR An empty pathname was specified.",location]];
            break;
        case EPFNOSUPPORT:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ EPFNOSUPPORT Protocol family not supported",location]];
            break;
        case EAFNOSUPPORT:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ EAFNOSUPPORT  Address family not supported by protocol family ",location]];
            break;
        case ECONNRESET:
            [self.logFeed majorErrorText:[NSString stringWithFormat:@"%@ ECONNRESET Connection reset by peer",location]];
            break;
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
            
        case EPROTONOSUPPORT:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ EPROTONOSUPPORT: The protocol type or the specified protocol is not supported within this domain.",location]];
            break;
        case EMFILE:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ EMFILE: The per-process descriptor table is full.",location]];
            break;
            
        case ENFILE:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ ENFILE: The system file table is full.",location]];
            break;
        case EBADF:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ EBADF: An invalid descriptor was specified",location]];
            break;
        case ENOTSOCK:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ ENOTSOCK: The argument s is not a socket",location]];
            break;
        case EFAULT:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ EFAULT:  An invalid  address or parameter was specified",location]];
            break;
        case EMSGSIZE:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ EMSGSIZE: The socket requires that message be sent atomically, and the size of the message to be sent made this impossible.",location]];
            break;
        case EAGAIN:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ EAGAIN: The socket is marked non-blocking and the requested operation would block.",location]];
            break;
        case ENOBUFS:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ ENOBUFS: Insufficient buffer space is available",location]];
            break;
        case EACCES:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ EACCES: Permission to create/use a socket of the specified type and/or protocol is denied.",location]];
            break;
        case EHOSTUNREACH:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ EHOSTUNREACH The destination address specified an unreachable host.",location]];
            break;
        case EADDRNOTAVAIL:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ EADDRNOTAVAIL The specified address is not available from the local machine..",location]];
            break;
        case EADDRINUSE:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ EADDRINUSE The specified address is already in use.",location]];
            break;
        case EINVAL:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ EINVAL The socket is already bound to an address. in bind(): The addrlen is wrong, or the socket was not in the AF_UNIX family",location]];
            break;
        case ENOTDIR:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ ENOTDIR A component of the path prefix is not a directory.",location]];
            break;
        case ENAMETOOLONG:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@  ENAMETOOLONG a part of the pathname or the pathname itself is too long",location]];
            break;
        case ENOENT:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ ENOENT A prefix component of the path name does not exist",location]];
            break;
        case ELOOP:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ ELOOP Too many symbolic links were encountered in translating the pathname",location]];
            break;
        case EIO:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ EIO An I/O error occurred while making the directory entry or allocating the inode.",location]];
            break;
        case EROFS:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ EROFS The name would reside on a read-only file system.",location]];
            break;
        case EISDIR:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ EISDIR An empty pathname was specified.",location]];
            break;
        case EPFNOSUPPORT:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ EPFNOSUPPORT Protocol family not supported",location]];
            break;
        case EAFNOSUPPORT:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ EAFNOSUPPORT  Address family not supported by protocol family ",location]];
            break;
        case ECONNRESET:
            [self.logFeed minorErrorText:[NSString stringWithFormat:@"%@ ECONNRESET Connection reset by peer",location]];
            break;
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

- (void)dump:(NSFileHandle *)filehandler
{
    NSMutableString *s = [[NSMutableString alloc]init];
    [s appendString:@"\n"];
    [s appendString:@"--------------------------------------------------------------------------------\n"];
    [s appendFormat:@"Layer: %@\n",layerName];
    [s appendString:@"--------------------------------------------------------------------------------\n"];
    [filehandler writeData: [s dataUsingEncoding:NSUTF8StringEncoding]];
}
@end
