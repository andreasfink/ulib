//
//  UMUtil.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"

@interface UMUtil : UMObject
{

}

+ (NSMutableData *)base32:(NSMutableData *)data;
+ (NSMutableData *)unbase32:(NSMutableData *)data;

/* encoding 0: as network byte order 32bit value */
/* encoding 1: as variable length 7 bit value(s).
               highest bits first. Bit #8 set means it was the last 7bit chunk */
/* encoding 2: as network byte order 64bit value */

//+ (void) appendULLToNSMutableData:(NSMutableData *)dat withValue: (unsigned long long) value usingEncoding:(int)encodingVariant;
//+ (unsigned long long) grabULLFromNSMutableData:(NSMutableData *)dat usingIndex: (int *) idx usingEncoding:(int)encodingVariant;
//+ (void) appendNSStringToNSMutableData:(NSMutableData *)dat withString: (NSString *) str usingEncoding:(int)enc;
//+ (NSString *) grabNSStringFromNSMutableData:(NSMutableData *)dat usingIndex: (int *) idx usingEncoding:(int)encodingVariant;
+ (NSString *) sysName;
+ (NSString *) nodeName;
+ (NSString *) release;
+ (NSString *) version;
+ (NSString *) version1;
+ (NSString *) version2;
+ (NSString *) version3;
+ (NSString *) version4;
+ (NSString *) machine;
+ (NSString *) getMacAddr: (char *)ifname;
+ (NSMutableArray *)getMacAddrs;
+ (long long) milisecondClock;
+ (uint32_t) random:(uint32_t)upperBound;
+ (uint32_t) random;
@end

NSString *UMBacktrace(void **stack_frames, size_t size);
