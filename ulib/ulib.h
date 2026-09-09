//
//  ulib.h
//  ulib
//
//  Created by Andreas Fink on 16.12.2011.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.

#import <ulib/UMAssert.h>
#import <ulib/UMObject.h>
#import <ulib/UMDirtyObject.h>
#import <ulib/UMDirtyBoolean.h>
#import <ulib/UMDirtyDouble.h>
#import <ulib/UMDirtyInteger.h>
#import <ulib/UMDirtyString.h>
#import <ulib/UMDirtyData.h>
#import <ulib/UMDirtyDate.h>
#import <ulib/NSData+ulib.h>
#import <ulib/NSString+ulib.h>
#import <ulib/NSArray+ulib.h>
#import <ulib/NSDictionary+ulib.h>
#import <ulib/NSNumber+ulib.h>
#import <ulib/NSObject+ulib.h>
#import <ulib/NSDate+ulib.h>
#import <ulib/NSMutableString+ulib.h>
#import <ulib/NSMutableArray+ulib.h>
#import <ulib/NSMutableData+ulib.h>
#import <ulib/UMIntegerWithHistory.h>
#import <ulib/UMStringWithHistory.h>
#import <ulib/UMDoubleWithHistory.h>
#import <ulib/UMDateWithHistory.h>
#import <ulib/UMDataWithHistory.h>
#import <ulib/UMHistoryLog.h>
#import <ulib/UMBackgrounder.h>
#import <ulib/UMBackgrounderWithQueue.h>
#import <ulib/UMTaskQueue.h>
#import <ulib/UMTaskQueueMulti.h>
#import <ulib/UMTaskQueueTask.h>
#import <ulib/UMFileTracker.h>
#import <ulib/UMSynchronizedDictionary.h>
#import <ulib/UMSynchronizedSortedDictionary.h>
#import <ulib/UMSynchronizedArray.h>
#import <ulib/UMDateTimeStuff.h>
#import <ulib/UMObjectStatisticEntry.h>
#import <ulib/UMObjectStatistic.h>
#import <ulib/UMPublicKey.h>
#import <ulib/UMPrivateKey.h>


#import <ulib/UMConfig.h>
#import <ulib/UMConfigParsedLine.h>
#import <ulib/UMConfigGroup.h>

#import <ulib/UMHost.h>
#import <ulib/UMSocket.h>
#import <ulib/UMSyslogClient.h>
#import <ulib/UMPacket.h>
#import <ulib/UMZMQSocket.h>

typedef enum
{
    HTTP_METHOD_GET = 0,
    HTTP_METHOD_POST = 1,
    HTTP_METHOD_HEAD = 2,
    HTTP_METHOD_OPTIONS = 3,
    HTTP_METHOD_TRACE = 4,
    HTTP_METHOD_PUT = 5,
    HTTP_METHOD_DELETE = 6
} UMHTTPMethod;

@class UMHTTPConnection;
@class UMHTTPServer;
@class UMHTTPRequest;
@class UMHTTPPageHandler;

#import <ulib/UMHTTPAuthenticationStatus.h>
#import <ulib/UMHTTPConnection.h>
#import <ulib/UMHTTPServer.h>
#import <ulib/UMHTTPSServer.h>
#import <ulib/UMHTTPPageHandler.h>
#import <ulib/UMHTTPServerAuthoriseResult.h>
#import <ulib/UMHTTPRequest.h>
#import <ulib/UMHTTPCookie.h>
#import <ulib/UMHTTPPageRef.h>
#import <ulib/UMHTTPPageCache.h>
#import <ulib/UMHTTPClient.h>
#import <ulib/UMHTTPClientRequest.h>

#import <ulib/UMHTTPTask_ReadRequest.h>



#import <ulib/UMJsonParser.h>
#import <ulib/UMJsonWriter.h>
#import <ulib/UMJsonStreamParser.h>
#import <ulib/UMJsonStreamParserAdapter.h>
#import <ulib/UMJsonStreamWriter.h>
#import <ulib/NSArray+ulib.h>


#import <ulib/UMLogLevel.h>
#import <ulib/UMLogEntry.h>
#import <ulib/UMLogFile.h>
#import <ulib/UMLogConsole.h>
#import <ulib/UMLogBuffered.h>
#import <ulib/UMLogDestination.h>
#import <ulib/UMLogHandler.h>
#import <ulib/UMLogFeed.h>

#import <ulib/UMLayer.h>
#import <ulib/UMLayerTask.h>
#import <ulib/UMLayerUserProtocol.h>

#import <ulib/UMQueueSingle.h>
#import <ulib/UMQueueNull.h>
#import <ulib/UMQueueMulti.h>
#define  UMQueue    #error

#import <ulib/UMSleeper.h>
#import <ulib/UMThroughputCounter.h>
#import <ulib/UMUtil.h>
#import <ulib/UMUUID.h>
#import <ulib/UMAverageDelay.h>
#import <ulib/UMMicroSec.h>
#import <ulib/UMTimer.h>
#import <ulib/UMTimerBackgrounder.h>
#import <ulib/UMMutex.h>
#import <ulib/UMAtomicCounter.h>
#import <ulib/UMAtomicDate.h>
#import <ulib/UMThreadHelpers.h>
#import <ulib/UMCommandLine.h>
#import <ulib/UMProtocolBuffer.h>
#import <ulib/UMNamedList.h> // the new implementation is now in ulibasn1
#import <ulib/UMStatistic.h>
#import <ulib/UMStatisticEntry.h>
#import <ulib/UMRegexMatch.h>
#import <ulib/UMRegex.h>
#import <ulib/UMDigitTree.h>
#import <ulib/UMDigitTreeEntry.h>
#import <ulib/UMObjectTree.h>
#import <ulib/UMObjectTreeEntry.h>
#import <ulib/UMPrometheus.h>
#import <ulib/UMPrometheusMetric.h>
#import <ulib/UMPrometheusThroughputMetric.h>
#import <ulib/UMPrometheusMetricUptime.h>

#import <ulib/UMRedisSession.h>
#import <ulib/UMRedisStatus.h>
#import <ulib/UMRedisCommand.h>

#import <ulib/UMFileTrackingMacros.h>
#import <ulib/UMCommandActionProtocol.h>
#import <ulib/UMScanner.h>
#import <ulib/UMScannerChar.h>
#import <ulib/UMSyntaxAction.h>
#import <ulib/UMSyntaxContext.h>
#import <ulib/UMSyntaxToken.h>
#import <ulib/UMSyntaxToken_Const.h>
#import <ulib/UMSyntaxToken_Name.h>
#import <ulib/UMSyntaxToken_Number.h>
#import <ulib/UMSyntaxToken_Digits.h>
#import <ulib/UMTokenizer.h>
#import <ulib/UMTokenizerWord.h>

#import <ulib/UMPlugin.h>
#import <ulib/UMPluginHandler.h>
#import <ulib/UMPluginDirectory.h>
#import <ulib/UMBackgrounderWithQueues.h>
#import <ulib/UMConstantStringsDict.h>
#import <ulib/UMCountryCodePrefixDigitTree.h>
#import <ulib/UMCountryDigitTree.h>
#import <ulib/UMHTTP2Connection.h>
#import <ulib/UMHTTP2Frame.h>
#import <ulib/UMHTTP2Server.h>
#import <ulib/UMHTTP2Session.h>
#import <ulib/UMHTTPURLHandler.h>
#import <ulib/UMHTTPWebSocketFrame.h>
#import <ulib/UMHistoryLogEntry.h>
#import <ulib/UMJsonStreamParserAccumulator.h>
#import <ulib/UMJsonStreamParserState.h>
#import <ulib/UMJsonStreamWriterAccumulator.h>
#import <ulib/UMJsonStreamWriterState.h>
#import <ulib/UMJsonTokeniser.h>
#import <ulib/UMJsonUTF8Stream.h>
#import <ulib/UMKeypair.h>
#import <ulib/UMMemoryHeader.h>
#import <ulib/UMPKI.h>
#import <ulib/UMPool.h>
#import <ulib/UMSSLCertificate.h>
#import <ulib/UMSerialPort.h>
#import <ulib/dmi_decode_path.h>
#import <ulib/UMStdIo.h>

#import <ulib/UMASN1Object.h>
#import <ulib/UMASN1ObjectConstructed.h>
#import <ulib/UMASN1ObjectPrimitive.h>
#import <ulib/UMASN1ObjectDescriptor.h>
#import <ulib/UMASN1ObjectIdentifier.h>
#import <ulib/UMASN1Tag.h>
#import <ulib/UMASN1Length.h>
#import <ulib/UMASN1BitString.h>
#import <ulib/UMASN1Boolean.h>
#import <ulib/UMASN1Choice.h>
#import <ulib/UMASN1EndOfContents.h>
#import <ulib/UMASN1Integer.h>
#import <ulib/UMASN1Null.h>
#import <ulib/UMASN1OctetString.h>
#import <ulib/UMASN1Sequence.h>
#import <ulib/UMASN1Set.h>
#import <ulib/UMASN1UTF8String.h>
#import <ulib/UMASN1Enumerated.h>
#import <ulib/UMASN1Real.h>
#import <ulib/UMZMQSocket+ASN1.h>
#import <ulib/UMASN1NamedList.h>

#import <ulib/UMRpcServer_AuthenticateProtocol.h>
#import <ulib/UMRpcClient.h>
#import <ulib/UMRpcServer.h>
#import <ulib/UMRpcError.h>
#import <ulib/UMRpcFlag.h>
#import <ulib/UMRpcMessageType.h>
#import <ulib/UMRpcMessage.h>
#import <ulib/UMRpcHandler.h>
#import <ulib/UMRpcClient.h>
#import <ulib/UMRpcMessage_GenericError.h>
#import <ulib/UMRpcMessage_HeartbeatRequest.h>
#import <ulib/UMRpcMessage_HeartbeatResponse.h>
#import <ulib/UMRpcMessage_LoginRequest.h>
#import <ulib/UMRpcMessage_LoginResponse.h>
#import <ulib/UMRpcMessage_LogoutRequest.h>
#import <ulib/UMRpcMessage_LogoutResponse.h>
#import <ulib/UMRpcMessage_TestRequest.h>
#import <ulib/UMRpcMessage_TestResponse.h>
#import <ulib/UMRpcServer.h>
#import <ulib/UMRpcSession.h>
#import <ulib/UMRpcCommandHandler.h>
#import <ulib/UMRpcSessionHandler.h>
#import <ulib/UMRpcMessageDecoder.h>

#import <ulib/UMLayerSctp.h>
#import <ulib/UMLayerSctpUserProtocol.h>
#import <ulib/UMSctpTask_AdminAttach.h>
#import <ulib/UMSctpTask_AdminDetach.h>
#import <ulib/UMSctpTask_AdminSetConfig.h>
#import <ulib/UMSctpTask_AdminInit.h>
#import <ulib/UMSctpTask_Close.h>
#import <ulib/UMSctpTask_Data.h>
#import <ulib/UMSctpTask_Manual_ForceOutOfService.h>
#import <ulib/UMSctpTask_Manual_InService.h>
#import <ulib/UMSctpTask_Open.h>
#import <ulib/UMLayerSctpUser.h>
#import <ulib/UMLayerSctpUserProfile.h>
#import <ulib/UMLayerSctpApplicationContextProtocol.h>
#import <ulib/UMSocketSCTPRegistry.h>
#import <ulib/UMSocketSCTPListener2.h>

#import <ulib/UMDbDriverType.h>
#import <ulib/UMDbQueryType.h>
#import <ulib/UMDbTable.h>
#import <ulib/UMDbPool.h>
#import <ulib/UMDbQuery.h>
#import <ulib/UMDbQueryCondition.h>
#import <ulib/UMDbQueryPlaceholder.h>
#import <ulib/UMDbResult.h>
#import <ulib/UMDbSession.h>
#import <ulib/UMDbTableDefinition.h>
#import <ulib/UMDbFieldDefinition.h>
#import <ulib/UMDbFileSession.h>
#import <ulib/UMMySQLSession.h>
#import <ulib/UMPgSQLSession.h>
#import <ulib/UMSqLiteSession.h>
#import <ulib/UMDbRedisSession.h>
#import <ulib/UMDbMySqlInProgress.h>

void ulibdb_startup(void);
void ulibdb_shutdown(void);
void ulibdb_thread_init(void);
void ulibdb_thread_exit(void);

NSString *ulib_version(void);
NSString *ulib_build(void);
NSString *ulib_builddate(void);
NSString *ulib_compiledate(void);

