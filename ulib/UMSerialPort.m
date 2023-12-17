//
//  UMSerialPort.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMSerialPort.h>
#import <ulib/UMMutex.h>
#import <ulib/UMAssert.h>

#import <sys/errno.h>
#include <errno.h>
#include <fcntl.h>
#include <termios.h>
#include <poll.h>

@implementation UMSerialPort

- (UMSerialPort *)init
{ 
    self = [super init];
    if(self)
    {
        _deviceName = @"/dev/ttyS0";
        _speed = 9600;
        _dataBits = 8;
        _parity = UMSerialPortParity_none;
        _stopBits = 1;
        _hardwareHandshake = NO;
        _fd = -1;
        _isOpen = NO;
        _serialPortLock = [[UMMutex alloc]initWithName:@"UMSerialPort"];
    }
    return self;
}



- (UMSerialPort *)initWithDevice:(NSString *)name
                           speed:(int)speed
                        dataBits:(int)dataBits
                        stopBits:(int)stopBits
                          partiy:(UMSerialPortParity)parity
               hardwareHandshake:(BOOL)handshake
{
    self = [super init];
    if(self)
    {
        _deviceName = name;
        _speed = speed;
        _dataBits = dataBits;
        _parity = parity;
        _stopBits = stopBits;
        _hardwareHandshake = handshake;
        _fd = -1;
        _isOpen = NO;
        NSString *s = [NSString stringWithFormat:@"UMSerialPort %@",name];
        _serialPortLock = [[UMMutex alloc]initWithName:s];
    }
    return self;
}

+ (UMSerialPortError)errorFromErrno:(int)e
{
    switch(e)
    {
        case EACCES:
            return UMSerialPortError_AccessDenied;
        case EDQUOT:
            return UMSerialPortError_QuotaExceeded;
        case EAGAIN:
            return UMSerialPortError_TryAgain;
        case EEXIST:
            return UMSerialPortError_PathAlreadyExists;
        case EINTR:
            return UMSerialPortError_Interrupted;
        case EINVAL:
            return UMSerialPortError_InvalidFlag;
        case EIO:
            return UMSerialPortError_InputOutputError;
        case EISDIR:
            return UMSerialPortError_IsDirectory;
        case ELOOP:
            return UMSerialPortError_TooManySymlinks;
        case EMFILE:
            return UMSerialPortError_MaximumNumberOfFilesReached;
        case ENFILE:
            return UMSerialPortError_FilesystemTableFull;
        case ENOENT:
            return UMSerialPortError_PathDoesNotExist;
        case ENOSPC:
            return UMSerialPortError_NoFreeInodes;
        case ENOTDIR:
            return UMSerialPortError_PathContainsNonDirectory;
        case ENXIO:
            return UMSerialPortError_DeviceDoesNotExist;
        case EOPNOTSUPP:
            return UMSerialPortError_NotSupported;
        case EOVERFLOW:
            return UMSerialPortError_Overflow;
        case EROFS:
            return UMSerialPortError_ReadOnlyFileSystem;
        case ETXTBSY:
            return UMSerialPortError_SharedSegmentBusy;
        case EBADF:
            return UMSerialPortError_BadFileName;
        default:
            return UMSerialPortError_Unspecified;
    }
}

- (UMSerialPortError)open
{
    UMMUTEX_LOCK(_serialPortLock);

    if(_isOpen)
    {
        [self close];
    }
    _fd = open(_deviceName.UTF8String, O_RDWR | O_NONBLOCK | O_NOCTTY);
    if(_fd < 0)
    {
        UMSerialPortError err =  [UMSerialPort errorFromErrno:errno];
        UMMUTEX_UNLOCK(_serialPortLock);
        return err;
    }
    _isOpen = YES;

    struct termios tios;
    memset(&tios,0x00,sizeof(tios));

    tcgetattr(_fd, &tios);
    /* Block until a charactor is available, but it only needs to be one*/
    tios.c_cc[VMIN]    = 1;
    tios.c_cc[VTIME]   = 0;
    tios.c_cflag      &= ~(CSIZE|PARENB);
    switch(_dataBits)
    {
        case 5:
            tios.c_cflag      |= CS5;
            break;
        case 6:
            tios.c_cflag      |= CS6;
            break;
        case 7:
            tios.c_cflag      |= CS7;
            break;
        case 8:
        default:
            tios.c_cflag      |= CS8;
            break;
    }
    if(_stopBits == 2)
    {
        tios.c_cflag      |= CSTOPB;
    }
    else
    {
        tios.c_cflag      &= ~(CSTOPB);
    }
    switch(_parity)
    {
        case UMSerialPortParity_none:
            tios.c_cflag      &= ~(PARENB);
            tios.c_cflag      &= ~(PARODD);
            break;
        case UMSerialPortParity_even:
            tios.c_cflag      &= ~(PARODD);
            tios.c_cflag      |= PARENB;
            break;
        case UMSerialPortParity_odd:
            tios.c_cflag      |= PARENB;
            tios.c_cflag      |= PARODD;
            break;
    }

    /* Input Flags,*/
    /* Turn off all input flags that interfere with the byte stream:
     * BRKINT - generate SIGINT when receiving BREAK, ICRNL - translate
     * NL to CR, IGNCR - ignore CR, IGNBRK - ignore BREAK,
     * INLCR - translate NL to CR, IXON - use XON/XOFF flow control,
     * ISTRIP - strip off eighth bit.
     */
    tios.c_iflag &= ~(BRKINT|ICRNL|IGNCR|IGNBRK|INLCR|IXON|ISTRIP);

    /* Other flags,*/
    /* Turn off all local flags that interpret the byte stream:
     * ECHO - echo input chars, ECHONL - always echo NL even if ECHO is off,
     * ICANON - enable canonical mode (basically line-oriented mode),
     * IEXTEN - enable implementation-defined input processing,
     * ISIG - generate signals when certain characters are received. */
    tios.c_lflag      &= ~(ECHO|ECHONL|ICANON|IEXTEN|ISIG);

    /* Output flags,*/
    /* Disable implementation defined processing on the output stream*/
    tios.c_oflag      &= ~OPOST;

    tios.c_iflag |= IGNBRK; /* ignore break & parity errors */
    tios.c_iflag &= ~INPCK; /* INPCK: disable parity check */
    tios.c_cflag |= HUPCL; /* hangup on close */
    tios.c_cflag |= CREAD; /* enable receiver */
    tios.c_cflag |= CLOCAL; /* Ignore modem control lines */
    tios.c_cflag &= ~CSIZE; /* set to 8 bit */
    tios.c_cflag |= CS8;
    tios.c_oflag &= ~ONLCR; /* no NL to CR-NL mapping outgoing */
    tios.c_iflag |= IGNPAR; /* ignore parity */
    tios.c_iflag &= ~INPCK;


#if defined(CRTSCTS)
    if(_hardwareHandshake)
    {
        tios.c_cflag |= CRTSCTS; /* enable hardware flow control */
    }
    else
    {
        tios.c_cflag &= ~CRTSCTS; /* disable hardware flow control */
    }
#endif
    tios.c_cc[VSUSP] = 0; /* otherwhise we can not send CTRL Z */

        /*
         if ( ModemTypes[privdata->modemid].enable_parity )
         tios.c_cflag ^= PARODD;
         */

    int ret = tcsetattr(_fd, TCSANOW, &tios); /* apply changes now */
    if (ret == -1)
    {
        NSLog(@"failed to set termios attribute on device %@",_deviceName);
    }
    tcflush(_fd, TCIOFLUSH);
    [self changeSpeed:_speed];

    UMMUTEX_UNLOCK(_serialPortLock);
    return UMSerialPortError_no_error;
}


- (void)changeSpeed:(int)newSpeed
{
    _speed = newSpeed;
    if(_isOpen==NO)
    {
        return;
    }

    UMMUTEX_LOCK(_serialPortLock);
    struct termios tios;
    memset(&tios,0x00,sizeof(tios));
    tcgetattr(_fd, &tios);
    int tspeed;
    switch (_speed)
    {
        case 300:
            tspeed = B300;
            break;
        case 1200:
            tspeed = B1200;
            break;
        case 2400:
            tspeed = B2400;
            break;
        case 4800:
            tspeed = B4800;
            break;
        case 9600:
            tspeed = B9600;
            break;
        case 19200:
            tspeed = B19200;
            break;
        case 38400:
            tspeed = B38400;
            break;
#ifdef B57600
        case 57600:
            tspeed = B57600;
            break;
#endif
#ifdef B115200
        case 115200:
            tspeed = B115200;
            break;
#endif
#ifdef B230400
        case 230400:
            tspeed = B230400;
            break;
#endif
#ifdef B460800
        case 460800:
            tspeed = B460800;
            break;
#endif
#ifdef B500000
        case 500000:
            tspeed = B500000;
            break;
#endif
#ifdef B576000
        case 576000:
            tspeed = B576000;
            break;
#endif
#ifdef B921600
        case 921600:
            tspeed = B921600;
            break;
#endif
        default:
#if B9600 == 9600 /* if the speed parameter matchhes the speed exactly, it might be a working default */
            tspeed = _speed;
#else       /* otherwise we simply use 9600 as default */
            tspeed = B9600;
#endif
    }

    cfsetospeed(&tios, tspeed);
    cfsetispeed(&tios, tspeed);
    int ret = tcsetattr(_fd, TCSANOW, &tios); /* apply changes now */
    if (ret == -1)
    {
        NSLog(@"failed to set termios attribute(speed) on device %@",_deviceName);
    }
    tcflush(_fd, TCIOFLUSH);
    UMMUTEX_UNLOCK(_serialPortLock);
}

- (void)close
{
    UMMUTEX_LOCK(_serialPortLock);
    close(_fd);
    _fd = -1;
    _isOpen = NO;
    UMMUTEX_UNLOCK(_serialPortLock);
}

- (UMSerialPortError)writeData:(NSData *)data
{
    size_t len = data.length;
    if(len==0)
    {
        return UMSerialPortError_no_error;
    }

    if((_isOpen == NO) || (_fd < 0))
    {
        return UMSerialPortError_NotOpen;
    }

    const uint8_t *bytes = data.bytes;
    UMMUTEX_LOCK(_serialPortLock);
    ssize_t len2 = write(_fd,bytes,len);
    UMMUTEX_UNLOCK(_serialPortLock);

    if(len2 < 0)
    {
        return [UMSerialPort errorFromErrno:errno];
    }
    if(len2 != len)
    {
        return UMSerialPortError_not_all_data_written;
    }
    return UMSerialPortError_no_error;
}

- (NSData *)readDataWithTimeout:(int)timeoutInMs error:(UMSerialPortError *)errPtr
{
    if((_isOpen == NO) || (_fd < 0))
    {
        if(errPtr)
        {
            *errPtr = UMSerialPortError_NotOpen;
        }
        return NULL;
    }

    if([self isDataAvailable:timeoutInMs error:errPtr] == NO)
    {
        return NULL;
    }
    NSMutableData *data = [[NSMutableData alloc]init];
    uint8_t buffer[256];
    ssize_t r=1;
    UMMUTEX_LOCK(_serialPortLock);
    while(r>0)
    {
        /* we need to be in non blocking mode here */
        r = read(_fd,buffer,sizeof(buffer));
        if(r > 0)
        {
            [data appendBytes:buffer length:r];
        }
    }
    UMMUTEX_UNLOCK(_serialPortLock);
    if((r < 0) && (errPtr != NULL))
    {
        *errPtr = [UMSerialPort errorFromErrno:errno];
    }
    return data;
}

- (BOOL) isDataAvailable:(int)timeoutInMs error:(UMSerialPortError *)errPtr;
{
    if((_isOpen == NO) || (_fd < 0))
    {
        if(errPtr)
        {
            *errPtr = UMSerialPortError_NotOpen;
        }
        return NO;
    }

    BOOL hasData = NO;
    if((_isOpen == NO) || (_fd < 0))
    {
        if(errPtr)
        {
            *errPtr = UMSerialPortError_NotOpen;
        }
        return NO;
    }

    
    struct pollfd pollfds[1];
    int ret1;
    int ret2;
    int eno = 0;

    int events = POLLIN | POLLPRI | POLLERR | POLLHUP | POLLNVAL;

    memset(pollfds,0,sizeof(pollfds));
    pollfds[0].fd = _fd;
    pollfds[0].events = events;
    UMAssert(timeoutInMs<200000,@"timeout should be smaller than 20seconds");
    UMAssert(((timeoutInMs>100) || (timeoutInMs !=0) || (timeoutInMs !=-1)),@"timeout should be bigger than 100ms");

    errno = 99;

    
    UMMUTEX_LOCK(_serialPortLock);
    ret1 = poll(pollfds, 1, timeoutInMs);
    UMMUTEX_UNLOCK(_serialPortLock);

    UMSerialPortError returnError = UMSerialPortError_no_error;

    if (ret1 < 0)
    {
        eno = errno;
        /* error condition */
        if (eno != EINTR)
        {
            returnError = [UMSerialPort errorFromErrno:EBADF];
        }
        else
        {
            returnError = [UMSerialPort errorFromErrno:eno];
        }
    }
    else if (ret1 == 0)
    {
        returnError = UMSerialPortError_no_data_available;
    }
    else
    {
        eno = errno;
        /* we have some event to handle. */
        ret2 = pollfds[0].revents;
        if(ret2 & POLLERR)
        {
            returnError = [UMSerialPort errorFromErrno:eno];
        }
        else if(ret2 & POLLHUP)
        {
            returnError = UMSerialPortError_has_data_and_hup;
        }
        else if(ret2 & POLLNVAL)
        {
            returnError = [UMSerialPort errorFromErrno:eno];
        }
        else if(ret2 & POLLIN)
        {
            returnError =  UMSerialPortError_has_data;

        }
        else if(ret2 & POLLPRI)
        {
            returnError = UMSerialPortError_has_data;
        }
        /* we get alerted by poll that something happened but no data to read.
         so we either jump out of the timeout or something bad happened which we are not catching */
        else
        {
            returnError = [UMSerialPort errorFromErrno:eno];
        }
    }
    if(errPtr)
    {
        *errPtr = returnError;
    }
    if((returnError == UMSerialPortError_has_data) || (returnError == UMSerialPortError_has_data_and_hup))
    {
        hasData = YES;
    }
    return hasData;
}
@end
