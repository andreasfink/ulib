//
//  UMCommandLine.h
//  ulib
//
//  Created by Andreas Fink on 09.03.18.
//  Copyright © 2018 Andreas Fink (andreas@fink.org). All rights reserved.
//

/*
 
UMCommandLine is a helper object for a command line parsing

 Here is an example on how to use it:
 
 int main(int argc, const char *argv[])
 {
    // we define some general stuff about this app
    // its used by help and other diagnostic outputs
    NSDictionary *appDefinition = @ {
        @"version" : @"1.0",
        @"executable" : @"myutil",
        @"run-as" : @(argv[0]),
    };

    // we define a dictionary specifying what option flags and options are allowed
    // and what parameters they take
    // the following keys exist
    //   name : mandatory unique internal name of option
    //   short: optional short version -x
    //   long: optional long version --xxxxx
    //   help: mandatory   description of the help output
    //   argument: optional   naming of the argument. If present, the flag requires an optional parameter
    //
    // parameters can be called like -x argument or --xxxxx argument or  --xxxx=argument
 
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
      // convert C command line into array
      NSMutableArray *args = [[NSMutableArray alloc]init];
      for(int i=0;i<argc;i++)
      {
          [args addObject:@(argv[i])];
      }
      UMCommandLine *myCommandLine = [[UMCommandLine alloc]initWithArgs:args
                                                   commandLineDefintion:commandLineDefinition
                                                          appDefinition:appDefinition];
      [myCommandLine handleStandardArguments]; // takes care --help and --version 

      ...
      at this point the myCommandLine.params will contain a dictionary of all options (the key is the name from the definiton.
      for parameters with arguments the value is an array of the passed arguments.
      for parameters without arguments, the value is a NSValue representing the number of times the parameter appeared
      for example if you pass -vvvv you would have @{ "verbose" : 4 }
      mainArguments would contain all parameters you pass without options.
      if you pass -- then all following strings are considered mainArugments.
 */


#import <ulib/ulib.h>

@interface UMCommandLine : UMObject
{
    NSArray *_commandLineDefinition; /* an array of dictionary defining what parameters are allowed etc */
    NSArray *_commandLineArguments; /* as passed from main */
    NSMutableArray *_mainArguments;  /* the arguments passed on the command line without any options */
    NSMutableDictionary *_params;      /* a dictionary with option name as key and either a NSValue (integer) as counter of how many times the option occurred or an array of strings with all the options's parameters */
    NSDictionary *_appDefinition;
}

- (UMCommandLine *)initWithArgs:(NSArray *)args
           commandLineDefintion:(NSArray *)cld
                  appDefinition:(NSDictionary *)appDefinition;
- (NSDictionary *)params;
- (NSArray *)mainArguments;
- (void)printHelp;
- (void)printVersion;
- (void)handleStandardArguments; /* take care of --help and --version */

@end
