//
//  UMSerialPort.h
//  ulib
//
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"
#import "UMMutex.h"

#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>

typedef enum UMSerialPortParity
{
    UMSerialPortParity_none = 0,
    UMSerialPortParity_even = 1,
    UMSerialPortParity_odd = 2,
} UMSerialPortParity;

typedef enum UMSerialPortError
{
    UMSerialPortError_no_error = 0,
    UMSerialPortError_device_busy = 1,
    UMSerialPortError_no_data_available = 2,
    UMSerialPortError_TryAgain = 3,
    UMSerialPortError_has_data = 4,
    UMSerialPortError_has_data_and_hup = 5,

    UMSerialPortError_NotOpen = 97,
    UMSerialPortError_not_all_data_written = 98,
    UMSerialPortError_Unspecified = 99,
    UMSerialPortError_AccessDenied = 100,
    UMSerialPortError_QuotaExceeded = 101,
    UMSerialPortError_PathAlreadyExists = 102,
    UMSerialPortError_Interrupted = 103,
    UMSerialPortError_InvalidFlag = 104,
    UMSerialPortError_InputOutputError = 105,
    UMSerialPortError_IsDirectory = 106,
    UMSerialPortError_TooManySymlinks = 107,
    UMSerialPortError_MaximumNumberOfFilesReached = 108,
    UMSerialPortError_FilesystemTableFull = 109,
    UMSerialPortError_PathDoesNotExist = 110,
    UMSerialPortError_NoFreeInodes = 111,
    UMSerialPortError_PathContainsNonDirectory = 112,
    UMSerialPortError_DeviceDoesNotExist = 113,
    UMSerialPortError_NotSupported = 114,
    UMSerialPortError_Overflow = 115,
    UMSerialPortError_ReadOnlyFileSystem = 116,
    UMSerialPortError_SharedSegmentBusy = 117,
    UMSerialPortError_BadFileName = 118,
} UMSerialPortError;

@interface UMSerialPort : UMObject
{
    NSString            *_deviceName;
    int                 _speed; /* in BPS */
    int                 _dataBits;
    int                 _stopBits;
    UMSerialPortParity  _parity;
    BOOL                _hardwareHandshake;
    int                 _fd;
    BOOL                _isOpen;
    UMMutex             *_lock;
}


@property(readwrite,strong,atomic)  NSString           *deviceName;
@property(readwrite,assign,atomic)  int                speed;
@property(readwrite,assign,atomic)  int                dataBits;
@property(readwrite,assign,atomic)  int                stopBits;
@property(readwrite,assign,atomic)  UMSerialPortParity parity;
@property(readwrite,assign,atomic)  BOOL               hardwareHandshake;
@property(readonly,assign,atomic)   BOOL               isOpen;

- (UMSerialPort *)initWithDevice:(NSString *)name
                           speed:(int)speed
                        dataBits:(int)dataBits
                        stopBits:(int)stopBits
                          partiy:(UMSerialPortParity)parity
               hardwareHandshake:(BOOL)handshake;

- (UMSerialPortError)open;
- (void)close;
- (UMSerialPortError)writeData:(NSData *)data;
- (NSData *)readDataWithTimeout:(int)timeoutInMs error:(UMSerialPortError *)errPtr;
- (BOOL) isDataAvailable:(int)timeoutInMs error:(UMSerialPortError *)errPtr;

@end

