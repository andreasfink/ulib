 //
//  UMRedisSession.m
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "UMRedisSession.h"
#import "UniversalSocket.h"
#import "UniversalJson.h"
#import "UMRedisStatus.h"
#import "UniversalLog.h"
#import "UMUtil.h" /* for UMBacktrace */

#define SOCKET_EXCEPTION    @"redis.socket"
#define SYNTAX_EXCEPTION    @"redis.syntax"

@implementation UMRedisSession

@synthesize socket;
@synthesize hostName;
@synthesize status;

- (UMRedisSession *)initWithHost:(NSString *)hn
{
    return [self initWithHost:hn andPort:0];
}

- (UMRedisSession *)initWithHost:(NSString *)hostString andPort:(long)port;
{
    self = [super init];
    if(self)
    {
        socket = [[UMSocket alloc] initWithType:UMSOCKET_TYPE_TCP4ONLY];
        if (!socket)
        {
            NSString *msg = [NSString stringWithFormat:@"[UMRedisSession initWithSocket]  Couldn't connect to server).\r\n"];
            [logFeed majorError:0 withText:msg];
            return nil;
        }
    
        status = REDIS_STATUS_HAS_SOCKET;
        autoReconnect = YES;
    
        hostName = hostString;
        UMHost *host = [[UMHost alloc] initWithName:hostName];
        [socket setRemoteHost:host];
        if (port == 0)
        {
            port = REDIS_PORT;
        }
        [socket setRequestedRemotePort:port];
    }
    
    return self;
}

- (BOOL)reinitWithHost
{
    socket = [[UMSocket alloc] initWithType:UMSOCKET_TYPE_TCP4ONLY];
    if (!socket)
    {
        NSString *msg = [NSString stringWithFormat:@"[UMRedisSession initWithSocket]  Couldn't connect to server).\r\n"];
        [logFeed majorError:0 withText:msg];
        return NO;
    }
    
    status = REDIS_STATUS_HAS_SOCKET;
    
    UMHost *host = [[UMHost alloc] initWithName:hostName];
    [socket setRemoteHost:host];
    [socket setRequestedRemotePort:REDIS_PORT];
    
    return YES;
}

- (BOOL)connect
{
    UMSocketError sErr;
    
    sErr = [socket connect];
    if (sErr != UMSocketError_no_error)
    {
        NSString *msg = [NSString stringWithFormat:@"[UMRedisSession connect] Couldn't connect to server error %d, status %d.\n", sErr, status];
        [logFeed majorError:0 withText:msg];
        socket = nil;
        if(autoReconnect==NO)
        {
            @throw([NSException exceptionWithName:@"CAN_NOT_CONNECT"
                                           reason:NULL
                                         userInfo:@{
                                                    @"sysmsg" : @"Couldn't connect to server",
                                                    @"func": @(__func__),
                                                    @"obj":self,
                                                    @"backtrace": UMBacktrace(NULL,0)
                                                    }
                    ]);
        }
        return [self restart];
    }

    status = REDIS_STATUS_CONNECTED;
    return YES;
}

- (NSString *)description
{
    NSMutableString *desc = [NSMutableString stringWithString:@"redis session dump starts\r\n"];
    [desc appendFormat:@"socket %@\r\n", socket];
    [desc appendFormat:@"status %@\r\n", [self redisStatusToString]];
    [desc appendFormat:@"host name %@\r\n", hostName];
    [desc appendString:@"redis session dump ends\r\n"];
    return desc;
}

- (BOOL)restart:(NSException *)socketException
{
    status = REDIS_STATUS_OFF;
    
    NSDictionary *userInfo = [socketException userInfo];
    NSString *command = [userInfo objectForKey:@"command"];
    NSString *errorString = [socketException reason];
    NSString *msg = [NSString stringWithFormat:@"[UMRedisSession restart]: cannot do [UMRedisSession %@], error %@, restarting", command, errorString];
    [logFeed majorError:0 inSubsection:@"redis" withText:msg];
    
    BOOL success = [self restart];
    return success;
}

- (BOOL)restart
{
    status = REDIS_STATUS_OFF;
    BOOL success = NO;
    BOOL haveSocket = [self reinitWithHost];
    if (haveSocket == NO)
    {
        return NO;
    }
    status = REDIS_STATUS_HAS_SOCKET;
    [logFeed majorError:0 inSubsection:@"redis" withText:@"[UMRedisSession restart]: restarting after 30 seconds"];

    UMSocketError sErr = [socket connect];
    success = sErr == UMSocketError_no_error;
    if (success)
    {
        status = REDIS_STATUS_CONNECTED;
    }
    return success;
}

- (BOOL)stop
{
    [socket close];
    socket = nil;
    status = REDIS_STATUS_OFF;
    return YES;
}

+ (NSException *) socketException:(UMSocketError)e whenRedisCommand:(NSString *)command
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
     userInfo[@"command"]=command;
     userInfo[@"backtrace"] = UMBacktrace(NULL,0);

    return [NSException exceptionWithName:SOCKET_EXCEPTION
                                   reason:[UMSocket getSocketErrorString:e]
                                 userInfo:userInfo];
}

+ (NSException *) syntaxException:(NSString *)s
{
    return [NSException exceptionWithName:SYNTAX_EXCEPTION
                                   reason:s
                                 userInfo:@{@"backtrace": UMBacktrace(NULL,0) }];
}


- (NSData *)readReplyLine
{
    UMSocketError userr = UMSocketError_no_error;

    NSMutableData *rxdata = NULL;
    
    userr = [socket receiveLineToCRLF:&rxdata];
    while(userr == UMSocketError_try_again)
    {
        userr = [socket receiveLineToCRLF:&rxdata];
    }
    if(userr != UMSocketError_no_error && userr != UMSocketError_try_again)
    {
        @throw [UMRedisSession socketException:userr whenRedisCommand:@"readReplyLine"];
    }
    return rxdata;
}

- (NSString *)readStatusReply
{
    NSData *reply = nil;
    NSString *s = nil;
    
    while (!reply)
    {
        @try
        {
            reply = [self readReplyLine];
        }
        @catch (NSException *socketException)
        {
            BOOL success = [self restart:socketException];
            if (success == NO)
            {
                return s;
            }
        }
    }
    
    if (reply)
    {
        s = [[NSString alloc ]initWithData:reply encoding:NSUTF8StringEncoding];
    }
    
    NSArray *parts = [s componentsSeparatedByString:@": "];
    NSString *first = parts[0];
    if ([first isEqualToString:@"-ERR Protocol error"])
    {
        [logFeed majorError:0 withText:[NSString stringWithFormat:@"redis protocol error %@", parts[1]]];
    }
    return s;
}

/*
In a Status Reply the first byte of the reply is "+"
In an Error Reply the first byte of the reply is "-"
In an Integer Reply the first byte of the reply is ":"
In a Bulk Reply the first byte of the reply is "$"
In a Multi Bulk Reply the first byte of the reply s "*"
*/

- (id)readReply
{
    NSString *s = nil;
    NSData *reply = nil;
    while (!reply)
    {
        @try
        {
            reply = [self readReplyLine];
        }
        @catch (NSException *socketException)
        {
            BOOL success = [self restart:socketException];
            if (success == NO)
            {
                return [[NSNumber alloc] initWithInt:-1];
            }
        }
    }
    s = [[NSString alloc ]initWithData:reply encoding:NSUTF8StringEncoding];
    const char *cstring = [s UTF8String];

    long len = -1;
    sscanf(&cstring[1],"%ld",&len);

    switch(cstring[0])
    {
        case '+':
        {
            UMRedisStatus *redisStatus = [[UMRedisStatus alloc]init];
            redisStatus.ok = YES;
            redisStatus.statusString = s;
            return redisStatus;
        }
        case '-':
        {
            UMRedisStatus *redisStatus = [[UMRedisStatus alloc]init];
            redisStatus.ok = NO;
            redisStatus.statusString = s;
            return redisStatus;
        }
        case ':':
        {
            NSNumber *n = @(len);
            return n;
        }
        case '$':
        {
            if(len==-1)
            {
                /* this negative answer */
                return [[NSNull alloc]init];
            }
            if(len < -1)
            {
                @throw [UMRedisSession syntaxException:@"was expecting a value which is greater or equal than -1"];
            }
            if(len == 0)
            {
                return [NSData data];
            }
            NSData *rxdata1 = NULL;
            UMSocketError userr = UMSocketError_try_again;
            while(userr == UMSocketError_try_again)
            {
                userr = [socket receive:len+2 to:&rxdata1]; /* includes the CRLF */
            }
            if(userr != UMSocketError_no_error)
            {
                @throw [UMRedisSession socketException:userr whenRedisCommand:@"readReply"];
            }
            NSData *rxdata = [rxdata1 subdataWithRange:NSMakeRange(0, len)];
            return (NSData *)rxdata;
            break;
        }
        case '*':
        {
            NSMutableArray *marray = [[NSMutableArray alloc]init];
            int i;
            for(i=0; i<len;i++)
            {
                NSData *reply1 = [self readReplyLine];
                NSMutableString *s1 = nil;
                if (!reply1)
                {
                    return s1;
                }
                s1 = [[NSMutableString alloc ]initWithData:reply1 encoding:NSUTF8StringEncoding];
                
                const char *cstring1 = [s1 UTF8String];
                long len1 = -1;
                sscanf(&cstring1[1],"%ld",&len1);
                
                NSData *rxdata1 = NULL;//[[NSMutableData alloc]init];
                
                UMSocketError userr = UMSocketError_try_again;
                while(userr == UMSocketError_try_again)
                {
                    userr = [socket receive:len1+2 to:&rxdata1]; /* includes the CRLF */
                }
                if(userr != UMSocketError_no_error)
                {
                    @throw [UMRedisSession socketException:userr whenRedisCommand:@"readReply"];
                }
                //[rxdata1 setLength:len1]; /* strips CR/LF */
                NSData *rxdata2 = [rxdata1 subdataWithRange:NSMakeRange(0, len1)];
                [marray addObject:rxdata2];
            }
            return (NSArray *)marray;
            break;
        }
        default:
        {
            @throw [UMRedisSession syntaxException:[NSString stringWithFormat:@"was expecting '$...','+...','-...' or ':...' but got '%@'",s]];
        }
    }
    return NULL;
}


- (NSInteger)readMultiBulkReplyHeader
{
    NSData *reply = [self readReplyLine];
    NSString *s = nil;
    if (!reply)
        return -1;
    
    s = [[NSString alloc ]initWithData:reply encoding:NSUTF8StringEncoding];
    const char *cstring = [s UTF8String];
    if(cstring[0]!='*')
    {
        @throw [UMRedisSession syntaxException:[NSString stringWithFormat:@"was expecting $... but got '%@'",s]];
    }
    long len = -1;
    sscanf(&cstring[1],"%ld",&len);
    if(len <= 0)
    {
        return 0;
    }
    return len;
}

//Fixme: should be handled on appilcation level
- (NSString *) setObject:(NSData *)value forKey:(NSString *)key
{
    @try
    {
        [self sendNSStringRaw:@"*3\r\n"];
    }
    @catch (NSException *socketException)
    {
        BOOL success = [self restart:socketException];
        if (success == NO)
            return nil;
    }
    
    [self sendObject:@"SET"];
    [self sendObject:key];
    [self sendObject:value];
    return [self readStatusReply];
}

- (id)getKeys:(id)keypattern
{
    [self sendNSStringRaw:@"*2\r\n"];
    [self sendObject:@"KEYS"];
    [self sendObject:keypattern];
    return [self readReply];

}
- (id)getObjectForKey:(id)key
{
    [self sendNSStringRaw:@"*2\r\n"];
    [self sendObject:@"GET"];
    [self sendObject:key];
    return [self readReply];
}


- (id)getLike
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMddHH"];
    NSString *ymdh = [formatter stringFromDate:[NSDate date]];
    id reply;
    
    NSString *keysLike = [NSString stringWithFormat:@"KEYS *%@*\r\n", ymdh];
    @try
    {
        [self sendNSStringRaw:keysLike];
    }
    @catch (NSException *socketException)
    {
        NSLog(@"we have an exception %@ at getLike", socketException);
        UMRedisStatus *redisStatus = [[UMRedisStatus alloc]init];
        redisStatus.exceptionRaised = YES;
        redisStatus.statusString = [socketException reason];
        return redisStatus;
    }
    
    reply = [self readReply];
    return reply;
}

- (id)getLike:(NSString *)tableName
      withKey:(NSString *)key
         like:(NSString *)ymdh
{
    id reply;
    
    NSString *keysLike = [NSString stringWithFormat:@"KEYS *%@*\r\n", ymdh];
    @try
    {
        [self sendNSStringRaw:keysLike];
    }
    @catch (NSException *socketException)
    {
        NSLog(@"we have an exception %@ at getLike:", socketException);
        UMRedisStatus *redisStatus = [[UMRedisStatus alloc]init];
        redisStatus.exceptionRaised = YES;
        redisStatus.statusString = [socketException reason];
        return redisStatus;
    }
    
    reply = [self readReply];
    return reply;
}

- (id)delObjectForKey:(id)key
{
    id reply;
    
    [self sendNSStringRaw:@"*2\r\n"];
    [self sendObject:@"DEL"];
    [self sendObject:key];
    reply = [self readReply];
    return reply;
}

- (id)expireKey:(id)key inSeconds:(NSNumber *)sec
{
    [self sendNSStringRaw:@"*3\r\n"];
    [self sendObject:@"EXPIRE"];
    [self sendObject:key];
    [self sendObject:sec];
    return [self readReply];
}


- (id)listDelForKey:(id)key andValue:(id)value
{
    [self sendNSStringRaw:@"*4\r\n"];
    [self sendObject:@"LREM"];
    [self sendObject:key];
    [self sendObject:@"0"];
    [self sendObject:value];
    return [self readReply];
}

- (id)listAddForKey:(id)key andValue:(id)value
{
    [self sendNSStringRaw:@"*3\r\n"];
    [self sendObject:@"RPUSH"];
    [self sendObject:key];
    [self sendObject:value];
    return [self readReply];
}

- (id)listLen:(id)key
{
    [self sendNSStringRaw:@"*2\r\n"];
    [self sendObject:@"LLEN"];
    [self sendObject:key];
    return [self readReply];
}

- (id)listGet:(id)key index:(int)i
{
    [self sendNSStringRaw:@"*3\r\n"];
    [self sendObject:@"LINDEX"];
    [self sendObject:key];
    [self sendObject:[NSString stringWithFormat:@"%d",i]];
    return [self readReply];
}

- (id)updateObject:(id)value forKey:(id)key
{
    [self sendNSStringRaw:@"*2\r\n"];
    [self sendObject:@"DEL"];
    [self sendObject:key];
    [self readReply]; /* we can ignore any errors here */

    [self sendNSStringRaw:@"*3\r\n"];
    [self sendObject:@"SET"];
    [self sendObject:key];
    [self sendObject:value];
    return [self readStatusReply];
}

- (id)updateJsonObject:(NSDictionary *)changedValues forKey:(id)key
{
    NSMutableDictionary *dict = [[self getJsonForKey:key]mutableCopy];
    if(dict == NULL)
    {
        dict = [[NSMutableDictionary alloc]init];
    }
    for(NSString *key2 in changedValues)
    {
        id newValue = [changedValues objectForKey:key2];
        [dict setObject:newValue forKey:key2];
    }
    return [self setJson:dict forKey:key];
}

- (id)increaseJsonObject:(NSDictionary *)changedValues forKey:(id)key
{
    NSMutableDictionary *dict = [[self getJsonForKey:key]mutableCopy];
    if(dict == NULL)
    {
        dict = [[NSMutableDictionary alloc]init];
    }
    for(NSString *key2 in changedValues)
    {
        id oldValue = [dict objectForKey:key2];
        if([oldValue isKindOfClass:[NSNumber class]])
        {
            NSNumber *old = oldValue;
            NSNumber *inc = [changedValues objectForKey:key2];
            double f = [old doubleValue];
            f = f + inc.doubleValue;
            [dict setObject:@(f) forKey:key2];
        }
    }
    return [self setJson:dict forKey:key];
}



- (id) setJson:(NSDictionary *)dict forKey:(id)key
{
    //NSLog(@"set json for key %@",key);

    UMJsonWriter *writer = [[UMJsonWriter alloc] init];
    NSData *data =[writer dataWithObject:dict];
    //NSLog(@"  data =%@",data);
    return [self setObject:data forKey:key];
}

- (NSDictionary *)getJsonForKey:(id)key
{
    //NSLog(@"get json for key %@",key);

    if(key==NULL)
    {
        return [[NSDictionary alloc]init];
    }
    
    id r = [self getObjectForKey:key];

    if(r == NULL)
    {
        return [[NSDictionary alloc]init];
    }
    if([r isKindOfClass:[NSNull class]])
    {
        return [[NSDictionary alloc]init];
    }
    else if([r isKindOfClass:[NSData class]])
    {
        NSData *data = r;
        UMJsonParser *parser = [[UMJsonParser alloc] init];
        NSDictionary *result;
        @try
        {
            result = [parser objectWithData:data];
        }

        @catch(id err)
        {
            NSLog(@"error decoding json for key:%@\ndata: %@\nError: %@",key,data,err);
            return [[NSDictionary alloc]init];
        }
        return result;
    }
    @throw([NSException exceptionWithName:@"redis" reason:@"unexpected result type" userInfo:@{@"r":r, @"backtrace": UMBacktrace(NULL,0)}]);
}

- (NSArray *)getListForKey:(id)key
{
    NSNumber *num = [self listLen:key];
    int n = [num intValue];
    int i;
    NSMutableArray *arr = [[NSMutableArray alloc]init];
    for(i=0;i<n;i++)
    {
        id obj =  [self listGet:key index:i];
        [arr addObject:obj];
    }
    return arr;
}

- (void)sendNSData:(NSData *)data
{
    UMSocketError userr = UMSocketError_no_error;
    
    NSUInteger len = [data length];
    
    userr = [socket sendString:[NSString stringWithFormat:@"$%lu\r\n",(unsigned long)len]];
    if(userr != UMSocketError_no_error)
    {
        @throw [UMRedisSession socketException:userr whenRedisCommand:@"sendNSData"];
    }
    userr = [socket sendData:data];
    if(userr != UMSocketError_no_error)
    {
        @throw [UMRedisSession socketException:userr whenRedisCommand:@"sendNSData"];
    }
    userr = [socket sendString:@"\r\n"];
    if(userr != UMSocketError_no_error)
    {
        @throw [UMRedisSession socketException:userr whenRedisCommand:@"sendNSData"];
    }
    return;
}

- (void)sendNSStringRaw:(NSString *)string;
{
    UMSocketError userr = UMSocketError_no_error;
    userr = [socket sendString:string];
    if(userr != UMSocketError_no_error)
    {
        @throw [UMRedisSession socketException:userr whenRedisCommand:@"sendNSStringRaw"];
    }
    return;
}

- (void)sendNSString:(NSString *)string;
{
    NSData *stringdata = [string dataUsingEncoding:NSUTF8StringEncoding];
    [self sendNSData:stringdata];
}

- (void)sendObject:(id)object
{
    if([object isKindOfClass:[NSData class]])
    {
        [self sendNSData:object];
    }
    else if ([object isKindOfClass:[NSString class]])
    {
        [self sendNSString:object];
    }
    else if ([object isKindOfClass:[NSValue class]])
    {
        [self sendNSString:[object stringValue]];
    }
    else
    {
        [self sendNSString:[object description]];
    }
}

- (long)lengthOfObject:(id)object
{
    if([object isKindOfClass:[NSData class]])
    {
        return [object length];
    }
    else if ([object isKindOfClass:[NSString class]])
    {
        return [object length];
    }
    else if ([object isKindOfClass:[NSValue class]])
    {
        return [[object stringValue] length];
    }
    else
    {
        return [[object description] length];
    }
    
    return [[object description] length];
}


- (NSString *) hSetObject:(NSDictionary *)dict forKey:(NSString *)key
{
    NSArray *dictKeys = [dict allKeys];
    NSString *reply = nil;
    NSMutableString *sendObject = nil;
    NSString *dictKey = nil;
    long len = 0;

    for(dictKey in dictKeys)
    {
        sendObject = [NSMutableString stringWithString:@"HSET "];
        [sendObject appendFormat:@"%@ ",key];
        NSMutableString *dictValue = [[dict objectForKey:dictKey] mutableCopy];
        
        if ([dictValue length] == 0)
            dictValue = [NSMutableString stringWithString:@"empty"];
        [dictValue replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:NSLiteralSearch range:NSMakeRange(0, [dictValue length])];
        [dictValue replaceOccurrencesOfString:@"'" withString:@"\'" options:NSLiteralSearch range:NSMakeRange(0, len = [dictValue length])];
        [dictValue insertString:@"\"" atIndex:len];
        [dictValue insertString:@"\"" atIndex:0];
        
        [sendObject appendFormat:@"%@ ", dictKey];
        [sendObject appendFormat:@"%@\r\n", dictValue];
        
        @try
        {
            [self sendNSStringRaw:sendObject];
        }
        @catch (NSException *socketException)
        {
            NSLog(@"we have an exception %@ at hSetObject:forKey:", socketException);
            reply = @":-1";
            return reply;
        }
        
        reply = [self readStatusReply];
    }
    
    return reply;
}

- (NSString *) hincrFields:(NSArray *)arr ofKey:(NSString *)key by:(long)incr
{
    id reply = nil;
    NSMutableString *sendObject = nil;
    
    for( id arrKey in arr)
    {
        sendObject = [NSMutableString stringWithString:@"HINCRBY "];
        [sendObject appendFormat:@"%@ ",key];
        [sendObject appendFormat:@"%@ ", arrKey];
        [sendObject appendFormat:@"%ld\r\n", incr];
        @try
        {
            [self sendNSStringRaw:sendObject];
        }
        @catch (NSException *socketException)
        {
            NSLog(@"we have an exception %@ at hincrFields", socketException);
            reply = @":-1";
            return reply;
        }

        reply = [self readStatusReply];
    }
    
    return reply;
}

- (NSString *) hincrFields:(NSArray *)arr ofKey:(NSString *)key byFloat:(float)incr
{
    id reply = nil;
    NSMutableString *sendObject = nil;
    
    for( id arrKey in arr)
    {
        sendObject = [NSMutableString stringWithString:@"HINCRBYFLOAT "];
        [sendObject appendFormat:@"%@ ", arrKey];
        [sendObject appendFormat:@"%@ ", key];
        [sendObject appendFormat:@"%5.0f\r\n", incr];
        @try
        {
            [self sendNSStringRaw:sendObject];
        }
        @catch (NSException *socketException)
        {
            NSLog(@"we have an exception %@ at hincrbyfloat", socketException);
            reply = @":-1";
            return reply;

        }
        reply = [self readStatusReply];
    }
    
    return reply;
}

/* After error we restart but not resend*/
- (NSString *) hexistField:(NSString *)field ofKey:(NSString *)key
{
    NSString *reply = nil;
    NSMutableString *sendObject = [NSMutableString stringWithString:@"HEXISTS "];
    [sendObject appendFormat:@"%@ ",key];
    [sendObject appendFormat:@"%@\r\n", field];

    @try
    {
        [self sendNSStringRaw:sendObject];
    }
    @catch (NSException *socketException)
    {
        NSLog(@"we have an exception %@ at hexistField", socketException);
        reply = @":-1";
        return reply;
    }
    reply = [self readStatusReply];

    return reply;
}

- (NSString *)ping
{
    NSString *reply = nil;
    NSMutableString *sendObject = [NSMutableString stringWithString:@"PING\r\n"];
    
    @try
    {
        [self sendNSStringRaw:sendObject];
    }
    @catch (NSException *socketException)
    {
        NSLog(@"we have an exception %@ at ping", socketException);
        reply = @":-1";
        return reply;
    }
    
    reply = [self readStatusReply];
    return reply;
}

- (NSMutableDictionary *)hGetAllObjectForKey:(NSString *)inKey
{
    [self sendNSStringRaw:@"*2\r\n"];
    [self sendObject:@"HGETALL"];
    [self sendObject:inKey];
    id reply = [self readReply];
    
    if([reply isKindOfClass:[NSArray class]])
    {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
        long len = (long)[reply count];
        if((len % 2)!=0)
        {
            @throw [UMRedisSession syntaxException:@"unbalanced key/value pairs in reply"];
        }
        
        long i;
        for(i=0;i<len;i+=2)         // we use 2 items per loop
        {
            NSData *keyData = [reply objectAtIndex:i];
            NSString *key = [[NSString alloc ]initWithData:keyData encoding:NSUTF8StringEncoding];
            NSMutableString *value = [[NSMutableString alloc] initWithData:[reply objectAtIndex:i+1] encoding:NSUTF8StringEncoding];
            
            if ([value isEqualToString:@"empty"])
                value = [NSMutableString stringWithString:@" "];
            [value replaceOccurrencesOfString:@"\\\"" withString:@"\"" options:NSLiteralSearch range:NSMakeRange(0, [value length])];
            [value replaceOccurrencesOfString:@"\'" withString:@"'" options:NSLiteralSearch range:NSMakeRange(0, [value length])];
            [dict setObject:value forKey:key];
        }
        return dict;
    }
    return reply;
}

- (NSString *) redisStatusToString
{
    switch (status)
    {
        case REDIS_STATUS_OFF:
            return @"off";
        case REDIS_STATUS_HAS_SOCKET:
            return @"has socket";
        case REDIS_STATUS_MAJOR_FAILURE:
            return @"major failure";
        case REDIS_STATUS_MAJOR_FAILURE_RETRY_TIMER:
            return @"major failure retry timer";
        case REDIS_STATUS_CONNECTING:
            return @"connecting";
        case REDIS_STATUS_CONNECTED:
            return @"connected";
        case REDIS_STATUS_ACTIVE:
            return @"active";
        case REDIS_STATUS_CONNECT_RETRY_TIMER:
            return @"connect retry timer";
    }
    
    return @"N.N";
}

@end
