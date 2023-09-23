//
//  ulib.h
//  ulib
//
//  Created by Andreas Fink on 16.12.2011.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.

#import <ulib/UMAssert.h>
#import <ulib/UMObject.h>
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
#import <ulib/UMNamedList.h>
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

@interface ulib : NSObject
{
}

+ (NSString *) ulib_version;
+ (NSString *) ulib_build;
+ (NSString *) ulib_builddate;
+ (NSString *) ulib_compiledate;

@end
