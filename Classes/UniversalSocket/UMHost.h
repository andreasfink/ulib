//
//  UMHost.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"
#import "UMSocket.h"
@class UMMutex;

@interface UMHost : UMObject
{
	NSMutableArray	*_addresses;
	int				_isLocalHost;
	int				_isResolving;
	int				_isResolved;
	UMMutex			*_lock;
    NSString        *_name;
}

- (NSArray *)addresses;
- (void) setAddresses:(NSArray *)addresses;
@property(readwrite,strong)	NSString *name;
@property(readwrite,assign)	int isLocalHost;
@property(readwrite,assign)	int isResolved;
@property(readwrite,assign)	int isResolving;

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

@end
