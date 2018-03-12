//
//  UMCommandLine.m
//  ulib
//
//  Created by Andreas Fink on 09.03.18.
//  Copyright © 2018 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMCommandLine.h"

@implementation UMCommandLine


- (UMCommandLine *)initWithCommandLineDefintion:(NSArray *)cld
                                  appDefinition:(NSDictionary *)appDefinition
                                           argc:(int)argc
                                           argv:(const char *[])argv
{
    NSMutableArray *args = [[NSMutableArray alloc]init];
    for(int i=0;i<argc;i++)
    {
        [args addObject:@(argv[i])];
    }
    return [self initWithCommandLineDefintion:cld
                                appDefinition:appDefinition
                                         args:args];
    return self;
}

- (UMCommandLine *)initWithCommandLineDefintion:(NSArray *)cld
                                  appDefinition:(NSDictionary *)appDefinition
                                           args:(NSArray *)args
{
    self = [super init];
    if(self)
    {
        _internalMainArguments      = [[NSMutableArray alloc]init];
        _internalParams             = [[NSMutableDictionary alloc]init];
        _commandLineArguments = args;
        _commandLineDefinition = cld;
        _appDefinition = appDefinition;
        [self processCommandLineArguments];
    }
    return self;
}

- (NSDictionary *)params
{
    return [_internalParams copy];
}

- (NSArray *)mainArguments
{
    return [_internalMainArguments copy];
}

- (void)processCommandLineArguments
{
    NSUInteger n = _commandLineArguments.count;
    NSUInteger m = _commandLineDefinition.count;
    BOOL skip = 0;
    
    /* first we expand command line arguments with single charaters
     example out of -abc we make -a -b -c
     Note: if -a takes parameters then the parameter to -a will be "-b" and the -b option wont be parsed
     */
    NSMutableArray *expandedArgs = [[NSMutableArray alloc]init];
    [expandedArgs addObject:_commandLineArguments[0]];
    for(NSUInteger i=1;i<n;i++)
    {
        NSString *arg = _commandLineArguments[i];
        if([arg isEqualToString:@"--"])
        {
            [expandedArgs addObject:arg];
            skip = 1;
            continue;
        }
        else if(skip)
        {
            [expandedArgs addObject:arg];
            continue;
        }
        else if ([arg hasPrefix:@"--"])
        {
            [expandedArgs addObject:arg];
            continue;
        }
        else if (![arg hasPrefix:@"-"])
        {
            [expandedArgs addObject:arg];
            continue;
        }
        else
        {
            const char *str = arg.UTF8String;
            size_t len = strlen(str);
            for(size_t j=1;j<len;j++)
            {
                [expandedArgs addObject:[NSString stringWithFormat:@"-%c",str[j]]];
            }
        }
    }
    n = expandedArgs.count;
    skip=0;
    for(NSUInteger i=1;i<n;i++)
    {
        NSString *arg = expandedArgs[i];
        if([arg isEqualToString:@"--"])
        {
            skip = 1;
            continue;
        }
        else if(skip)
        {
            [_internalMainArguments addObject:arg];
            continue;
        }
        else if([arg hasPrefix:@"-"])
        {
            NSUInteger j=0;
            for(j=0;j<m;j++)
            {
                NSDictionary *def = _commandLineDefinition[j];
                NSString *longString = def[@"long"];
                NSString *shortString = def[@"short"];
                NSString *name = def[@"name"];
                NSString *argument = def[@"argument"];
                /* lets check the syntax --option or  -o */
                if(([longString isEqualToString:arg]) || ([shortString isEqualToString:arg]))
                {
                    if(argument)
                    {
                        if(_internalParams[name] == NULL)
                        {
                            _internalParams[name] = [[NSMutableArray alloc]init];
                        }
                        if(i<(n-1))
                        {
                            NSString *param = expandedArgs[++i];
                            [_internalParams[name] addObject:param];
                        }
                    }
                    else
                    {
                        if(_internalParams[name] == NULL)
                        {
                            _internalParams[name] = @(1);
                        }
                        else
                        {
                            _internalParams[name] = @( [_internalParams[name] intValue] +1);
                        }
                    }
                    break;
                }
                /* lets check the syntax --option=value or --option=value1,value2
                 Note: the comma separated list is not valid for  --option
                 so you can not do --option value1,value2 but you can do --option value1  --option value2 */
                else if((longString) &&(argument))
                {
                    NSString *prefix = [NSString stringWithFormat:@"%@=",longString];
                    if([arg hasPrefix:prefix])
                    {
                        if(_internalParams[name] == NULL)
                        {
                            _internalParams[name] = [[NSMutableArray alloc]init];
                        }
                        NSString *params_list= [arg substringFromIndex:prefix.length];
                        NSArray *multiparams = [params_list componentsSeparatedByString:@","];
                        for(NSUInteger k=0;k<multiparams.count;k++)
                        {
                            NSString *param = multiparams[k];
                            [_internalParams[name] addObject:param];
                        }
                        break;
                    }
                }
            }
            if(j==m)
            {
                fprintf(stderr,"\nWarning: unkown option %s\n",arg.UTF8String);
            }
        }
        else
        {
            [_internalMainArguments addObject:arg];
        }
    }
}

- (void)handleStandardArguments
{
    if(_internalParams[@"help"])
    {
        [self printHelp];
        exit(0);
    }
    if(_internalParams[@"version"])
    {
        [self printVersion];
        exit(0);
    }
}

- (void)printHelp
{
    NSUInteger m = _commandLineDefinition.count;
    NSMutableString *help = [[NSMutableString alloc]init];
    NSString *paramDef = _appDefinition[@"param-definition"];
    NSString *exe = _appDefinition[@"executable"];
    if(paramDef==NULL)
    {
        paramDef=@"";
    }
    [help appendFormat:@"Usage: %@ {options}  %@\n",exe,paramDef];
    [help appendFormat:@"\nValid options are:\n"];
    for(NSUInteger j=0;j<m;j++)
    {
        NSDictionary *def = _commandLineDefinition[j];
        NSString *arg = @"";
        NSString *arg_multi = NULL;
        if(def[@"argument"])
        {
            if([def[@"multi"] boolValue])
            {
                arg_multi = [NSString stringWithFormat:@"=[%@,...]",def[@"argument"]];
                arg = [NSString stringWithFormat:@" [%@]",def[@"argument"]];
            }
            arg = [NSString stringWithFormat:@" [%@]",def[@"argument"]];
        }
        if(def[@"short"])
        {
            [help appendFormat:@" %@%@\n",def[@"short"],arg];
        }
        if(def[@"long"])
        {
            [help appendFormat:@"%@%@\n",def[@"long"],arg];
        }
        if(arg_multi)
        {
            [help appendFormat:@"%@%@\n",def[@"long"],arg_multi];
        }
        else if (arg.length >0)
        {
            [help appendFormat:@"%@=[%@]\n",def[@"long"],def[@"argument"]];
        }
        if(def[@"help"])
        {
            [help appendFormat:@"  %@\n\n",def[@"help"]];
        }
    }
    fprintf(stderr,"\n%s",help.UTF8String);
}

- (void)printVersion
{
    NSString *exe = _appDefinition[@"executable"];
    NSString *ver = _appDefinition[@"version"];
    NSString *copyright = _appDefinition[@"copyright"];
    fprintf(stderr,"\n%s Version %s\n",exe.UTF8String,ver.UTF8String);
    if(copyright)
    {
        fprintf(stderr,"%s\n",copyright.UTF8String);
    }
}

- (UMCommandLine *)copyWithZone:(NSZone *)zone
{
    UMCommandLine *cmd = [[UMCommandLine allocWithZone:zone ]init];
    cmd.commandLineDefinition = [_commandLineDefinition copy];
    cmd.commandLineArguments = [_commandLineArguments copy];
    cmd.internalMainArguments = [_internalMainArguments copy];
    cmd.internalParams = [_internalParams copy];
    cmd.appDefinition = [_appDefinition copy];
    return cmd;
}
@end
