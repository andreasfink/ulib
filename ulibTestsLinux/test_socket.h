//
//  test_socket.h
//  ulib
//
//  Created by Aarno Syvanen 27.03.12.
//  Copyright (c) 2012 Andreas Fink
//

#import "UMSocket.h"
#import "UMLogFile.h"
#import "UMLogFeed.h"
#import "../ulibTests/UMTestCase.h"

typedef enum SocketStatus
{
    notRunning = 0,
    startingUp,
    running,
    connected,
    testingBuffer,
    testingReadLine,
    testingReadEverything,
    shuttingDown,
    shutDown,
    failed
} SocketStatus;

typedef enum ContentType
{
    Bytes = 0,
    CString,
    String,
    Data,
    MutableData,
    NotKnown
} ContentType;

void test_socket_tcp(void);
void test_socket_sctp(void);
void test_socket_tcp_error(void);
