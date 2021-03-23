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

- (UMConfig *)initWithFileName:(NSString *)file
{
    if (!file)
    {
        return nil;
    }
    self = [super init];
    if (self)
    {
        _fileName = [[NSString alloc] initWithString:file];
        _singleGroups = [[NSMutableDictionary alloc] init];
        _multiGroups = [[NSMutableDictionary alloc] init];
        _allowedSingleGroupNames = [[NSMutableDictionary alloc] init];
        _allowedMultiGroupNames = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (NSString *)description
{
    NSMutableString *desc;

    desc = [NSMutableString stringWithString:@"configuration file dump starts\n"];
    [desc appendFormat:@"configuration file was %@\n", _fileName];
    [desc appendFormat:@"it has single groups %@\n", _singleGroups];
    [desc appendFormat:@"and multigroups %@\n", _multiGroups];
    [desc appendFormat:@"%@ were allowed single groups\n", _allowedSingleGroupNames];
    [desc appendFormat:@"and %@ allowed multigroups\n", _allowedMultiGroupNames];
    [desc appendString:@"configuration file dump ends\n"];
    
    return desc;
}

- (void)allowSingleGroup:(NSString *)n
{
    [_allowedSingleGroupNames setObject:@"allowed" forKey:n];
}

- (void)disallowSingleGroup:(NSString *)n
{
    [_allowedSingleGroupNames removeObjectForKey:n];
}

- (void)allowMultiGroup:(NSString *)n
{
    [_allowedMultiGroupNames setObject:@"allowed" forKey:n];
}
- (void)disallowMultiGroup:(NSString *)n
{
    [_allowedMultiGroupNames removeObjectForKey:n];
}


-(UMConfigParsedLine *)parseSingeLine:(NSString *)lin
                                 file:(NSString *)fn
                                 line:(long)ln
{
    UMConfigParsedLine *pl = [[UMConfigParsedLine alloc]init];
    pl.filename = fn;
    pl.lineNumber = ln;
    pl.content = lin;

    if([lin hasPrefix:@"include"])
    {
        if(_verbose)
        {
            NSLog(@"%@",lin);
        }
        NSString *relativeFileName;
        NSString *directoryPath1;
        NSString *directoryPath2;
        NSString *lin2 = [[lin substringFromIndex:7] stringByTrimmingCharactersInSet:[UMObject whitespaceAndNewlineCharacterSet]];

        NSString *firstChar =  [lin2 substringToIndex:1];
        NSString *lastChar = [lin2 substringFromIndex:lin2.length-1];

        if(([firstChar isEqualToString:@"\""]) &&([lastChar isEqualToString:@"\""]))
        {
            /* Syntax:  include "filename"  */
            relativeFileName = [lin2 substringWithRange:NSMakeRange(1,lin2.length-2)];
            directoryPath1 = [fn stringByDeletingLastPathComponent];
            directoryPath2 = _systemIncludePath;
        }
        else if(([firstChar isEqualToString:@"<"]) &&([lastChar isEqualToString:@">"]))
        {
            /* Syntax:  include <filename>  */
            relativeFileName = [lin2 substringWithRange:NSMakeRange(1,lin2.length-2)];
            directoryPath1 = _systemIncludePath;
            directoryPath2 = [fn stringByDeletingLastPathComponent];
        }
        else if([firstChar isEqualToString:@"="])
        {
            relativeFileName =[[lin2 substringFromIndex:1] stringByTrimmingCharactersInSet:[UMObject whitespaceAndNewlineCharacterSet]];
            NSString *firstChar =  [relativeFileName substringToIndex:1];
            NSString *lastChar = [relativeFileName substringFromIndex:relativeFileName.length-1];

            if(([firstChar isEqualToString:@"\""]) &&([lastChar isEqualToString:@"\""]))
            {
                /* Syntax:   include="filename"  */
                relativeFileName = [relativeFileName substringWithRange:NSMakeRange(1,relativeFileName.length-2)];
                directoryPath1 = [fn stringByDeletingLastPathComponent];
                directoryPath2 = _systemIncludePath;
            }
            else if(([firstChar isEqualToString:@"<"]) &&([lastChar isEqualToString:@">"]))
            {
                /* Syntax:   include=<filename>  */
                relativeFileName = [relativeFileName substringWithRange:NSMakeRange(1,relativeFileName.length-2)];
                directoryPath1 = _systemIncludePath;
                directoryPath2 = [fn stringByDeletingLastPathComponent];
            }
            else
            {
                /* Syntax:   include=filename */
                directoryPath1 = [fn stringByDeletingLastPathComponent];
                directoryPath2 = _systemIncludePath;
            }
        }
        else
        {
            @throw([NSException exceptionWithName:@"config"
                                           reason:
                    [NSString stringWithFormat:
                     @"Can not parse include statement in file %@ line %ld\n%@",fn,ln,lin]
                                         userInfo:NULL]);
        }
        NSString *fullPath1;
        NSString *fullPath2;
        if([relativeFileName isAbsolutePath])
        {
            fullPath1 = [relativeFileName stringByStandardizingPath];
            fullPath2 = NULL;
        }
        else
        {
            fullPath1 = [[NSString stringWithFormat:@"%@/%@",directoryPath1,relativeFileName]stringByStandardizingPath];
            fullPath2 = [[NSString stringWithFormat:@"%@/%@",directoryPath2,relativeFileName]stringByStandardizingPath];
        }

        NSString *fullPath=fullPath1;
        NSArray *lines = [self readFromFile:fullPath1];
        if((lines==NULL) && (fullPath2==NULL))
        {
            @throw([NSException exceptionWithName:@"config"
                                           reason:
                    [NSString stringWithFormat:
                     @"Can not read include file referenced in file %@ line %ld\n%@",fn,ln,lin]
                                         userInfo:NULL]);
        }
        if(lines==NULL)
        {
            lines = [self readFromFile:fullPath2];
            if(lines==NULL)
            {
                @throw([NSException exceptionWithName:@"config"
                                               reason:
                        [NSString stringWithFormat:
                         @"Can not read include file referenced in file %@ line %ld\n%@",fn,ln,lin]
                                             userInfo:NULL]);
            }
            fullPath=fullPath2;
        }
        if(_verbose)
        {
            NSLog(@"included file %@",fullPath);
        }
        pl.includedLines   = lines;
    }
    return pl;
}

- (NSArray *)readFromFile
{
    return [self readFromFile:_fileName andAppend:_configAppend];
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
    if(err)
    {
        return NULL;
    }
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
    
    NSCharacterSet *whitespace  = [UMObject whitespaceAndNewlineCharacterSet];
    NSCharacterSet *quotes      = [NSCharacterSet characterSetWithCharactersInString:@"\""];
    
    _singleGroups = [[NSMutableDictionary alloc]init];
    _multiGroups = [[NSMutableDictionary alloc]init];

    if(_fileName==NULL)
    {
        @throw([NSException exceptionWithName:@"config"
                                       reason:@"property fileName is not set"
                                     userInfo:@{@"backtrace": UMBacktrace(NULL,0) }]);
    }
    
    BOOL noGroupsDefined = (_allowedSingleGroupNames==NULL || [_allowedSingleGroupNames count]==0) && (_allowedMultiGroupNames==NULL || [_allowedMultiGroupNames count] == 0);
    if(noGroupsDefined)
    {
        @throw([NSException exceptionWithName:@"config"
                                       reason:@"no group definitions are set. populate allowedSingleGroupNames or allowedMultiGroupNames"
                                     userInfo:@{@"backtrace": UMBacktrace(NULL,0) }]);
    }

    NSArray *configArray = [self readFromFile:_fileName];
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
        if([line hasPrefix:@"include"])
        {
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
        NSInteger n = part1.length;
        if(   ([part1 characterAtIndex:0] == '[')
           && ([part1 characterAtIndex:n-1] == ']'))
        {
            /* this is windows ini file style  [groupname] */
            part2 = [part1 substringWithRange:NSMakeRange(1,n-2)];
            part1 = @"group";
        }
        else
        {
            /* this is command option or kannel style group = groupname */
            part2 = [part2 stringByTrimmingCharactersInSet:whitespace];
            part2 = [part2 stringByTrimmingCharactersInSet:quotes];
        }
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
            if([_allowedSingleGroupNames objectForKey:part2])
            {
                currentGroup  = [_singleGroups objectForKey:part2];
                if(currentGroup)
                {
                    @throw([NSException exceptionWithName:@"config"
                                                   reason:[NSString stringWithFormat:
                                                           @"There is already a group with that name '%@:%ld': \"%@\"",
                                                           item.filename,item.lineNumber,item.content]
                                                 userInfo:@{@"backtrace": UMBacktrace(NULL,0) }]);
                }
                currentGroup = [[NSMutableDictionary alloc]init];
                [_singleGroups setObject:currentGroup forKey:part2];
            }
            
            /* MULTI ENTRY */
            else if([_allowedMultiGroupNames objectForKey:part2])
            {
                currentGroup = [[NSMutableDictionary alloc]init];
                NSMutableArray *currentItems  = [_multiGroups objectForKey:part2];
                if(currentItems == NULL)
                {
                    currentItems = [NSMutableArray arrayWithObject:currentGroup];
                    [_multiGroups setObject:currentItems forKey:part2];
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
    return [_singleGroups objectForKey:n];
}

- (NSArray *)getMultiGroups:(NSString *)n
{
    return [_multiGroups objectForKey:n];
}

+ (NSString *)environmentFilter:(NSString *)str
{
    NSRange r = [str rangeOfString:@"$"];
    if(r.location == NSNotFound)
    {
        return str;
    }
    return str;
}
@end
