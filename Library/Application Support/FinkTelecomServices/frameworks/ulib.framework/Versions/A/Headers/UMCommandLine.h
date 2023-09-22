//
//  UMCommandLine.h
//  ulib
//
//  Created by Andreas Fink on 09.03.18.
//  Copyright © 2018 Andreas Fink (andreas@fink.org). All rights reserved.
//

/*
 
UMCommandLine is a helper object for a command line parsing
It can be used independently of ulib if needed.
 
 Here is an example on how to use it:
 
 int main(int argc, const char *argv[])
 {
    // we define some general stuff about this app
    // its used by help and other diagnostic outputs
    NSDictionary *appDefinition = @ {
        @"version" : @"1.0",
        @"executable" : @"myutil",
        @"run-as" : @(argv[0]),
        @"copyright" : @"(c) 2018 bla bla",
        @"param-definition" : @"{input-file}",
    };

    // we define a dictionary specifying what option flags and options are allowed
    // and what parameters they take
    // the following keys exist
    //   name : mandatory unique internal name of option
    //   short: optional short version -x
    //   long: optional long version --xxxxx
    //   help: mandatory   description of the help output
    //   argument: optional   naming of the argument. If present, the flag
    //   requires an optional parameter
    //
    // options with parameters can be called like this
    //     -x argument
    //     --xlong argument
    //     --xlong=argument
    // if multipe items:
    //     -x argument1 -x argument2
    //     --xlong argument1 --xlong argument2
    //     --xlong=argument1 --xlong=argument2
    //     --xlong=argument1,argument2
    //
    // note: --xlong argument1,argument2  would result in a single
    // argument with value "argument1,argument2"
 
    NSArray *commandLineDefinition = @[
                                   @{
                                       @"name"  : @"version",
                                       @"short" : @"-V",
                                       @"long"  : @"--version",
                                       @"help"  : @"shows the software version"
                                       },
                                   @{
                                       @"name"  : @"verbose",
                                       @"short" : @"-v",
                                       @"long"  : @"--verbose",
                                       @"help"  : @"enables verbose mode"
                                       },
                                   @{
                                       @"name"  : @"help",
                                       @"short" : @"-h",
                                       @"long" : @"--help",
                                       @"help"  : @"shows the help screen",
                                     }];
                                   @{
                                       @"name"  : @"debug",
                                       @"short" : @"-h",
                                       @"long" : @"--help",
                                       @"argument" : @"debug-option",
                                       @"multi" : @(YES),
                                       @"help"  : @"shows the help screen",
                                   }];     // initialize the command line object
     UMCommandLine *cmd = [[UMCommandLine alloc]initWithCommandLineDefintion:commandLineDefinition
                                                               appDefinition:appDefinition
                                                                        argc:argc
                                                                        argv:argv];
 
      // takes care --help and --version
      [cmd handleStandardArguments];

      ...
      at this point the cmd.params will contain a dictionary of all options
      (the key is the name from the definiton).
      for options with arguments the value is an array of the passed arguments.
      for options without arguments, the value is a NSValue representing the
      number of times the parameter appeared for example if you pass -vvvv
      you would have @{ "verbose" : 4 }
      cmd.mainArguments would contain all parameters you pass without options.
      if you pass -- then all following strings are considered mainArugments.
 */


#import <Foundation/Foundation.h>

@interface UMCommandLine : NSObject
{
    NSArray *_commandLineDefinition; /* an array of dictionary defining what parameters are allowed etc */
    NSArray *_commandLineArguments; /* as passed from main */
    NSMutableArray *_internalMainArguments;  /* the arguments passed on the command line without any options */
    NSMutableDictionary *_internalParams;      /* a dictionary with option name as key and either a NSValue (integer) as counter of how many times the option occurred or an array of strings with all the options's parameters */
    NSDictionary *_appDefinition;
    NSString *_appName;
}

@property(readwrite,strong,atomic)  NSArray *commandLineDefinition;
@property(readwrite,strong,atomic)  NSArray *commandLineArguments;
@property(readwrite,strong,atomic)  NSDictionary *appDefinition;
@property(readwrite,strong,atomic)  NSMutableArray *internalMainArguments; /* this is only here for copyWithZone. use mainArguments and params instead */
@property(readwrite,strong,atomic)  NSMutableDictionary *internalParams;
@property(readwrite,strong,atomic)  NSString *appName;


- (UMCommandLine *)initWithCommandLineDefintion:(NSArray *)cld
                                  appDefinition:(NSDictionary *)appDefinition
                                           argc:(int)arc
                                           argv:(const char *[])arv;

- (UMCommandLine *)initWithCommandLineDefintion:(NSArray *)cld
                                  appDefinition:(NSDictionary *)appDefinition
                                           args:(NSArray *)args;
- (NSDictionary *)params;
- (NSArray *)mainArguments;
- (void)printHelp;
- (void)printVersion;
- (void)handleStandardArguments; /* take care of --help and --version */

- (UMCommandLine *)copyWithZone:(NSZone *)zone;

@end
