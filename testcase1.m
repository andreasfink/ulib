//
//  main.m
//  testcase1
//
//  Created by Andreas Fink on 16.04.2020.
//  Copyright © 2020 Andreas Fink. All rights reserved.
//

#import <ulib/ulib.h>

int main(int argc, const char * argv[])
{
    @autoreleasepool
    {
	UMNamedList *nl = [[UMNamedList alloc]initWithPath:@"/opt/estp/named-lists//jimtest" name:@"jimtest"];
	[nl reload];
        [nl dump];
        [nl removeEntry:@"test2"];
        [nl dump];
    }
    return 0;
}

