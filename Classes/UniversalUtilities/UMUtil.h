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
+ (NSString *) osRelease;
+ (NSString *) version;
+ (NSString *) version1;
+ (NSString *) version2;
+ (NSString *) version3;
+ (NSString *) version4;
+ (NSString *) machine;
+ (NSString *) getMacAddrForInterface: (NSString *)ifname;
+ (NSArray *)getArrayOfMacAddresses;
+ (NSDictionary<NSString *,NSString *>*)getMacAddrs; /*!< returns a NSDictionary with interface name as key and mac-address as value */
+ (NSDictionary<NSString *,NSString *>*)getMacAddrsWithCaching:(BOOL)useCache;
+ (NSArray *)getNonLocalIPs;

/* this returns a dictionary of array of dictionaries.
 It is a dictionary with the interface name being the key and content being an array of IP address properties.
 An ip address property is a dictionary with "address" and "netmask" entries
*/
+ (NSDictionary<NSString *,NSArray<NSDictionary<NSString *,NSString *> *> *>*)getIpAddrs;
+ (NSDictionary<NSString *,NSArray<NSDictionary<NSString *,NSString *> *> *>*)getIpAddrsWithCaching:(BOOL)useCache;

+ (NSString *)getMachineSerialNumber; /*!< returns the machines serial number if it can be read */
+ (NSString *)getMachineUUID; /*!< returns the machines UUID if it can be read */
+ (NSArray *)getCPUSerialNumbers; /* !< returns the CPU serial if it can be read */
+ (NSArray *)readChildProcess:(NSArray *)args; /* !< creates a subprocess with the array elements as arguments. Executes it and returns an array of lines returned */

+ (long long) milisecondClock;
+ (uint32_t) random:(uint32_t)upperBound;
+ (uint32_t) randomFrom:(uint32_t)lowerBound to:(uint32_t)upperBound;
+ (uint32_t) random;
@end

NSString *UMBacktrace(void **stack_frames, size_t size);
uint64_t ulib_get_thread_id(void);
