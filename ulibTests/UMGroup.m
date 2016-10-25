//
//  UMGroup.m
//  ulib
//
//  Created by Aarno Syvänen on 08.05.12.
//  Copyright (c) 2012 Andreas Fink
//

#import "UMGroup.h"
#import "UMDbTable.h"
#import "UMDbQuery.h"
#import "UMDbPool.h"
#import "UMDbSession.h"
#import "UMPgSQLSession.h"
#import "UMConfig.h"
#import "UMDbDriverType.h"

@interface UMGroup (PRIVATE)

-(void)groupLoadByGid:(unsigned long)gid goingDown:(BOOL)mustQuit;
-(void)loadFromRow:(NSArray *)row addPrivFields:(BOOL)hasPriv;
-(NSMutableArray *)groupLoadListGoingDown:(BOOL)mustQuit;

@end

@implementation UMGroup (PRIVATE)

-(void)loadFromRow:(NSArray *)row addPrivFields:(BOOL)hasPriv;
{
    gid = [[row objectAtIndex:0] integerValue];
    groupName = [row objectAtIndex:1];
    maxCnt = [[row objectAtIndex:2] integerValue];
    curCnt = [[row objectAtIndex:3] integerValue];
    updMax = [[row objectAtIndex:4] integerValue];
    groupPass = [row objectAtIndex:5];
    
}

-(void)groupLoadByGid:(unsigned long)Gid goingDown:(BOOL)mustQuit
{
    NSArray *row;
    NSString *sql = [NSString stringWithFormat:@"SELECT %@ from %@ where gid='%lu'", groupFieldNames2, tableName, Gid];
    
    BOOL sret = [session connect];
    if (sret == NO)
        goto error;
    
    UMDbResult *result = [session queryWithMultipleRowsResult:sql allowFail:NO];
    
    if (!result)
        goto error;
    
    row = [result fetchRow];
    [self loadFromRow:row addPrivFields:NO];
    
error:
    
    [session disconnect];
}

-(NSMutableArray *)groupLoadListGoingDown:(BOOL)mustQuit
{
    NSArray *row;
    UMGroup *g;
    long count = 0;
    long i = 0;
    NSMutableArray *groups = nil;;
    NSString *sql = [NSString stringWithFormat:@"SELECT %@ from %@ order by gid", groupFieldNames2, tableName];
    
    BOOL sret = [session connect];
    if (sret == NO)
        goto end;
    
    UMDbResult *result = [session queryWithMultipleRowsResult:sql allowFail:NO];
    if (!result)
        goto end;
    
    count = [result rowsCount];
    while (i < 0)
    {
        row = [result fetchRow];
        if (row)
        {
            g = [[UMGroup alloc] init];
            [g loadFromRow:row addPrivFields:NO];
            [groups addObject:g];
            
        }
        ++i;
    }
    
end:
    [session disconnect];
    return groups;
}

@end

@implementation UMGroup

@synthesize groupName;
@synthesize groupPass;
                 
- (UMGroup *)init
{
    if((self = [super init]))
    {
        gid = -1;
        groupName = nil;
        maxCnt = -1;
        curCnt = -1;
        updMax = -1;
        groupPass = nil;
    }
    return self;
}

- (UMGroup *)initWithConfigFile:(NSString *)file
{
    NSString *poolName;
    NSString *host;
    NSString *databaseName;
    NSString *driver;
    NSString *user;
    NSString *pass;
    long port, minSessions, maxSessions;
    
    if((self = [super init]))
    {
        groupFieldNames2 = @"gid,group_name,max_cnt,cur_cnt,upd_cnt,upd_max,group_password,"
        "priv_admin,priv_uid,priv_gid,priv_login,priv_pwd,priv_pri,priv_defpri,priv_method,"
        "priv_smsc,priv_msc,priv_sccpsrc,priv_sccppfx,priv_shortid,priv_longid,priv_imsi,"
        "priv_tz,priv_ts,priv_speed,priv_url_id,priv_rt,priv_max_cnt,priv_cur_cnt,priv_mo_grp,"
        "priv_defopc,priv_defdpc,priv_deftcap_type";
        
        pool = [[UMDbPool alloc] init];
        
        UMConfig *cfg = [[[UMConfig alloc] initWithFileName:file] autorelease];
        
        [cfg allowSingleGroup:@"auth-table"];
        [cfg read]; 
        
        NSDictionary *grp = [cfg getSingleGroup:@"auth-table"];
        if (!grp)
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"UMGroup. init: configuration file must have group auth-table" userInfo:nil];
        
        long enable = 1;
        enable = [[grp objectForKey:@"enable"] integerValue];
        
        poolName = [grp objectForKey:@"pool-name"];
        if (!poolName)
            poolName = @"";
        
        host = [grp objectForKey:@"host"];
        if (!host)
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"UMGroup: init: configuration file must contain host name" userInfo:nil];
        
        databaseName = [grp objectForKey:@"database-name"];
        if (!databaseName)
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"UMGroup: init: configuration file must contain database name" userInfo:nil];
        
        driver = @"pgsql";
        
        user = [grp objectForKey:@"user"];
        if (!user)
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"UMGroup; init: configuration file must contain user name" userInfo:nil];
        
        pass = [grp objectForKey:@"pass"];
        if (!pass)
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"UMGroup: init: configuration file must contain password" userInfo:nil];
        
        tableName = [grp objectForKey:@"table"];
        if (!tableName)
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"UMGroup: init: configuration file must contain name of table of users" userInfo:nil];
        
        port = -1;
        port = [[grp objectForKey:@"port"] integerValue];
        minSessions = -1;
        minSessions = [[grp objectForKey:@"min-sessions"] integerValue];
        maxSessions = - 1;
        maxSessions = [[grp objectForKey:@"max-sessions"] integerValue];
        
        pool.poolName = [NSString stringWithString:poolName];
        pool.hostName = [NSString stringWithString:host];
        pool.dbName = [NSString stringWithString:databaseName];
        pool.dbDriverType = UMDriverTypeFromString([NSString stringWithString:driver]);
        pool.user = [NSString stringWithString:user];
        pool.pass = [NSString stringWithString:pass];
        pool.socket = nil;
        
        if(minSessions > 0)
        {
            pool.minSessions = (int)minSessions;
        }
        else
        {
            pool.minSessions = DEFAULT_MIN_DBSESSIONS;
        }
        
        if(maxSessions > 0)
        {
            pool.maxSessions = (int)maxSessions;
        }
        else
        {
            pool.maxSessions = DEFAULT_MAX_DBSESSIONS;
        }
        
        if(port > 0)
        {
            pool.port = (int)port;
        }
        else
        {
            pool.port = DEFAULT_PGSQL_PORT;
        }
        
        session = [[UMDbSession alloc] initWithPool:pool];
        if (!session)
            goto error;
        
        groupName = nil;
        groupPass = nil;
        globalGroupLock = [[NSLock alloc] init];
        globalGroupList = [self groupLoadListGoingDown:NO];
        
    }
    return self;
    
error:
    [globalGroupLock release];
    [globalGroupList release];
    [pool release];
    [session release];
    return nil;
}

- (void)dealloc
{
    NSUInteger	cnt;
	int i;
	UMGroup *g;
	
	if (!globalGroupList) 
    {
        [pool release];
	    [globalGroupLock release]; 
        globalGroupLock = nil;
        [super dealloc];
	    return;
	}
    
	[globalGroupLock lock];
	cnt = [globalGroupList count];
	
	for (i = 0; i < cnt; i++) 
    {
		g = [globalGroupList objectAtIndex:i];
		[g flushGoingDown:YES];
	}
	
	[globalGroupList release];
	[globalGroupLock unlock];
	[globalGroupLock release];
	globalGroupLock = nil;
	globalGroupList = nil;
    [groupName release];
    [groupPass release];
    
    [super dealloc];
}

- (void)flushGoingDown:(BOOL)mustQuit
{
    NSString *sql;
    
    if (updCnt > 0) 
    {
        sql = [NSString stringWithFormat:@"UPDATE %@ set cur_cnt = cur_cnt + '%lu' where gid='%lu'", tableName, updCnt, gid];
        updCnt = 0;
        
        BOOL sret = [session connect];
        if (sret == YES)
        {
            [logFeed debug:0 inSubsection:subsection withText:sql];
            [session queriesWithNoResult:sql allowFail:NO];
            [session disconnect];
        }
    }
    
    if (!mustQuit)
	    [self groupLoadByGid:gid goingDown:mustQuit];
}

- (UMGroup *)authenticateWithUser:(NSString *)userName andPassword:(NSString *)password
{
    UMGroup *grp;
    int i;
	NSUInteger n;
	
	[globalGroupLock lock];
	n = [globalGroupList count];
	for (i = 0; i < n; i++) {
		grp = [globalGroupList objectAtIndex:i];
		if (grp) 
        {
			if ([[grp groupName] compare:userName] == NSOrderedSame) 
            {
				if ([[grp groupPass] compare:password] == NSOrderedSame) 
                {
					[globalGroupLock unlock];
					return grp;
				}
			}
		}
	}
	[globalGroupLock unlock];
	
	grp = nil;
    return grp;
}

@end
