//
//  UMHost.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"
#import "UMSocket.h"

@interface UMHost : UMObject
{
	NSMutableArray	*addresses;
	int				isLocalHost;
	int				isResolving;
	int				isResolved;
	NSLock			*lock;
    NSString        *name;
}

@property(readwrite,strong)	NSMutableArray  *addresses;
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

@end
