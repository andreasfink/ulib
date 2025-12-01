//
//  UMHost.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMObject.h>
#import <ulib/UMSocket.h>
@class UMMutex;

@interface UMHost : UMObject
{
	NSMutableArray	*_addresses;
    BOOL			_isLocalHost;
    BOOL			_isResolving;
    BOOL            _isResolved;
	UMMutex			*_hostLock;
    NSString        *_name;
}

- (NSArray *)addresses;
- (void) setAddresses:(NSArray *)addresses;
@property(readwrite,strong)	NSString *name;
@property(readwrite,assign,atomic)	BOOL isLocalHost;
@property(readwrite,assign,atomic)	BOOL isResolved;
@property(readwrite,assign,atomic)	BOOL isResolving;

- (UMHost *)initWithLocalhost;
- (UMHost *)initWithLocalhostAddresses:(NSArray *)permittedAddresses;
- (UMHost *)initWithName:(NSString *)name;
- (UMHost *)initWithAddress:(NSString *)name;
- (NSString*)description;
- (void)addAddress:(NSString *)a;
- (void)resolve;
- (NSString *)address:(UMSocketType)type;
- (int)resolved;
- (int)resolving;
+ (NSString *)localHostName;
- (NSString *)address;
@end
