//
//  UMConfig.m
//  ulib
//
//  Created by Andreas Fink on 16.12.11.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMConfig.h"
#import "UMConfigParsedLine.h"
#import "UMUtil.h" /* for UMBacktrace */

#ifdef LINUX
    #include <unistd.h>
#endif

extern NSString *UMBacktrace(void **stack_frames, size_t size);

@implementation UMConfig

@synthesize verbose;
@synthesize allowedSingleGroupNames;
@synthesize allowedMultiGroupNames;
@synthesize fileName;
@synthesize singleGroups;

- (UMConfig *)initWithFileName:(NSString *)file
{
    if (!file)
    {
        return nil;
    }
    self = [super init];
    if (self)
    {
        fileName = [[NSString alloc] initWithString:file];
        singleGroups = [[NSMutableDictionary alloc] init];
        multiGroups = [[NSMutableDictionary alloc] init];
        allowedSingleGroupNames = [[NSMutableDictionary alloc] init];
        allowedMultiGroupNames = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (NSString *)description
{
    NSMutableString *desc;

    desc = [NSMutableString stringWithString:@"configuration file dump starts\n"];
    [desc appendFormat:@"configuration file was %@\n", fileName];
    [desc appendFormat:@"it has single groups %@\n", singleGroups];
    [desc appendFormat:@"and multigroups %@\n", multiGroups];
    [desc appendFormat:@"%@ were allowed single groups\n", allowedSingleGroupNames];
    [desc appendFormat:@"and %@ allowed multigroups\n", allowedMultiGroupNames];
    [desc appendString:@"configuration file dump ends\n"];
    
    return desc;
}

- (void)allowSingleGroup:(NSString *)n
{
    [allowedSingleGroupNames setObject:@"allowed" forKey:n];
}
- (void)disallowSingleGroup:(NSString *)n
{
    [allowedSingleGroupNames removeObjectForKey:n];
}

- (void)allowMultiGroup:(NSString *)n
{
    [allowedMultiGroupNames setObject:@"allowed" forKey:n];
}
- (void)disallowMultiGroup:(NSString *)n
{
    [allowedMultiGroupNames removeObjectForKey:n];
}

-(UMConfigParsedLine *)parseSingeLine:(NSString *)lin file:(NSString *)fn line:(long)ln
{
    UMConfigParsedLine *pl = [[UMConfigParsedLine alloc]init];
    pl.filename = fn;
    pl.lineNumber = ln;
    pl.content = lin;

    if([lin length]>7)
    {
        if([[lin substringToIndex:7] isEqualToString:@"include"])
        {
            if(verbose>0)
            {
                NSLog(@"include found");
            }

            NSArray *parts = [lin componentsSeparatedByString:@"\""];
            if([parts count] !=3)
            {
                if(verbose>0)
                {
                    NSLog(@"parts count is not 3. Pars are %@",parts);
                }
                @throw([NSException exceptionWithName:@"config"
                                               reason:
                        [NSString stringWithFormat:
                         @"Can not parse include statement in file %@ line %ld\n%@",fn,ln,lin]
                                             userInfo:@{@"backtrace": UMBacktrace(NULL,0) }]);
            }
            
            NSString *relativeFileName = [parts objectAtIndex:1];
            NSString *fullPath  = [relativeFileName stringByStandardizingPath];
            NSString *filename  = [fullPath lastPathComponent];
            NSString *newPath   = [fullPath stringByDeletingLastPathComponent];
            
            if(verbose>0)
            {
                NSLog(@"relativeFileName: %@",relativeFileName);
                NSLog(@"fullPath: %@",fullPath);
                NSLog(@"filename: %@",filename);
                NSLog(@"newPath: %@",newPath);
            }
            NSString *oldPath = [[NSFileManager defaultManager] currentDirectoryPath];
            if(verbose>0)
            {
                NSLog(@"oldPath: %@",oldPath);
            }
#ifdef LINUX
            chdir([newPath UTF8String]);
#else
            [[NSFileManager defaultManager] changeCurrentDirectoryPath:newPath];
#endif           
            if(verbose>0)
            {
                NSLog(@"newPath: %@",newPath);
                NSLog(@"newPath: %@",[[NSFileManager defaultManager] currentDirectoryPath]);
            }
            
            NSArray *lines = [self readFromFile:filename];
#ifdef LINUX
            chdir([oldPath UTF8String]);
#else
            [[NSFileManager defaultManager] changeCurrentDirectoryPath:oldPath];
#endif
            pl.includedLines   = lines;
        }
    }
    return pl;
}

- (NSArray *)readFromFile
{
    return [self readFromFile:fileName andAppend:_configAppend];
}

- (NSArray *)readFromFile:(NSString *)fn
{
    return [self readFromFile:fn andAppend:_configAppend];
}

- (NSArray *)readFromFile:(NSString *)fn andAppend:(NSString *)append
{
    BOOL errIgnore = NO;
    NSError *err = NULL;
    
    NSString *fullPath  = [fn stringByStandardizingPath];
    NSString *filename  = [fullPath lastPathComponent];
    NSString *newPath   = [fullPath stringByDeletingLastPathComponent];
    NSString *oldPath   = [[NSFileManager defaultManager] currentDirectoryPath];
#ifdef LINUX
    chdir([newPath UTF8String]);
#else
    [[NSFileManager defaultManager] changeCurrentDirectoryPath:newPath];
#endif
    NSString *configFile = [NSString stringWithContentsOfFile:filename
                                                     encoding:NSUTF8StringEncoding
                                                        error:&err];
    if(_configAppend)
    {
        if((configFile==NULL) && (_configAppend.length > 0))
        {
            /* if the config file can not be found but command line options are passed via configAppend, we ignore the error */
            errIgnore = YES;
            configFile = _configAppend;
        }
        else
        {
            configFile = [NSString stringWithFormat:@"%@%@",configFile,_configAppend];
        }
    }
    if(err)
    {
        NSString *s = [NSString stringWithFormat:@"Can not read file %@. Error %@",fn,err];
        if(errIgnore == YES)
        {
            NSLog(@"%@",s);
        }
        else
        {
            @throw([NSException exceptionWithName:@"config"
                                           reason:s
                                         userInfo:@{@"backtrace": UMBacktrace(NULL,0) }]);
        }
    }
    
    NSArray *lines = [configFile componentsSeparatedByString:@"\n"];
    NSMutableArray *config = [[NSMutableArray alloc]init];
    
    long linenumber = 0;
    for (NSString *line in lines)
    {
        linenumber++;
        [config addObject:[self parseSingeLine:line file:fn line:linenumber]];
    }
#ifdef LINUX
    chdir([oldPath UTF8String]);
#else
    [[NSFileManager defaultManager] changeCurrentDirectoryPath:oldPath];
#endif
    return config;
}

- (void)read
{
    NSMutableDictionary *currentGroup = NULL;
    
    NSCharacterSet *whitespace  = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSCharacterSet *quotes      = [NSCharacterSet characterSetWithCharactersInString:@"\""];
    
    singleGroups = [[NSMutableDictionary alloc]init];
    multiGroups = [[NSMutableDictionary alloc]init];

    if(fileName==NULL)
    {
        @throw([NSException exceptionWithName:@"config"
                                       reason:@"property fileName is not set"
                                     userInfo:@{@"backtrace": UMBacktrace(NULL,0) }]);
    }
    
    BOOL noGroupsDefined = (allowedSingleGroupNames==NULL || [allowedSingleGroupNames count]==0) && (allowedMultiGroupNames==NULL || [allowedMultiGroupNames count] == 0);
    if(noGroupsDefined)
    {
        @throw([NSException exceptionWithName:@"config"
                                       reason:@"no group definitions are set. populate allowedSingleGroupNames or allowedMultiGroupNames"
                                     userInfo:@{@"backtrace": UMBacktrace(NULL,0) }]);
    }

    NSArray *configArray = [self readFromFile:fileName];
    configArray =[UMConfigParsedLine flattenConfig:configArray];
    for(UMConfigParsedLine *item in configArray)
    {
        NSString *line = [item.content stringByTrimmingCharactersInSet:whitespace];
        if([line length]<1)
        {
            //currentGroup = NULL;
            continue;
        }
        if([line isEqualToString:@"end-group"])
        {
            currentGroup = NULL;
            continue;
        }

        if('#' == [line characterAtIndex:0])
        {
            continue;
        }
        
        NSRange r = [line rangeOfString:@"="];
        if(r.length==0)
        {
            @throw([NSException exceptionWithName:@"config"
                                           reason:[NSString stringWithFormat:
                                                   @"No equalsign in line '%@:%ld': \"%@\"",
                                                   item.filename,item.lineNumber,item.content]
                                         userInfo:@{@"backtrace": UMBacktrace(NULL,0) }]);
        }

        NSString *part1 = [line substringToIndex:r.location];
        NSString *part2 = [line substringFromIndex:r.location+1];
        part1 = [part1 stringByTrimmingCharactersInSet:whitespace];
        part1 = [part1 lowercaseString];
        part2 = [part2 stringByTrimmingCharactersInSet:whitespace];
        part2 = [part2 stringByTrimmingCharactersInSet:quotes];
        if([part1 isEqualToString:@"group"])
        {
            /*
            if(currentGroup != NULL)
            {
                NSString *reason = [NSString stringWithFormat:
                                    @"Group inside group doesnt make sense '%@:%ld': \"%@\"",
                                    item.filename,item.lineNumber,item.content];
                @throw([NSException exceptionWithName:@"config" reason:reason userInfo:@{@"backtrace": UMBacktrace(NULL,0) }]);
            }
             */
            /* SINGLE ENTRY */
            if([allowedSingleGroupNames objectForKey:part2])
            {
                currentGroup  = [singleGroups objectForKey:part2];
                if(currentGroup)
                {
                    @throw([NSException exceptionWithName:@"config"
                                                   reason:[NSString stringWithFormat:
                                                           @"There is already a group with that name '%@:%ld': \"%@\"",
                                                           item.filename,item.lineNumber,item.content]
                                                 userInfo:@{@"backtrace": UMBacktrace(NULL,0) }]);
                }
                currentGroup = [[NSMutableDictionary alloc]init];
                [singleGroups setObject:currentGroup forKey:part2];
            }
            
            /* MULTI ENTRY */
            else if([allowedMultiGroupNames objectForKey:part2])
            {
                currentGroup = [[NSMutableDictionary alloc]init];
                NSMutableArray *currentItems  = [multiGroups objectForKey:part2];
                if(currentItems == NULL)
                {
                    currentItems = [NSMutableArray arrayWithObject:currentGroup];
                    [multiGroups setObject:currentItems forKey:part2];
                }
                else
                {
                    [currentItems addObject:currentGroup];
                }
            }
            else
            {
                NSString *reason = [NSString stringWithFormat:
                                    @"UMConfig: read: Don't know how to parse group '%@:%ld': \"%@\"",
                                    item.filename,item.lineNumber,item.content];
                NSLog(@"%@",reason);
                currentGroup = NULL;
                //@throw([NSException exceptionWithName:@"config" reason:reason userInfo:@{@"backtrace": UMBacktrace(NULL,0) }]);
            }
        }
        if(currentGroup[part1]) /* we already have a line like this, we make an array out of it, if its not already an array */
        {
            id o = currentGroup[part1];

            NSMutableArray *a;
            if([o isKindOfClass:[NSString class]])
            {
                a = [[NSMutableArray alloc]init];
                [a addObject:o];
            }
            else if([o isKindOfClass:[NSMutableArray class]])
            {
                a = o;
            }
            [a addObject:part2];
            currentGroup[part1] = a;
        }
        else
        {
            currentGroup[part1] = part2;
        }
    }
}

- (NSDictionary *)getSingleGroup:(NSString *)n
{
    return [singleGroups objectForKey:n];
}

- (NSArray *)getMultiGroups:(NSString *)n
{
    return [multiGroups objectForKey:n];
}

@end
