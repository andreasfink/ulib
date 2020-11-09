//
//  main.c
//  testcase1
//
//  Created by Andreas Fink on 16.04.2020.
//  Copyright © 2020 Andreas Fink. All rights reserved.
//

#import <ulib/ulib.h>
#include <stdio.h>

int main(int argc, const char * argv[])
{
    @autoreleasepool
    {
        char buffer[256];
        const char *tmpcontent = "test2\neeee";
        const char *s = tmpnam(&buffer[0]);
        FILE *f = fopen(s,"w+");
        if(f==NULL)
        {
            fprintf(stderr,"tmpfile creation failed");
            exit(-1);
        }
        if(1!=fwrite(tmpcontent,sizeof(tmpcontent),1,f))
        {
            fprintf(stderr,"tmpfile writing failed");
            exit(-1);
        }
        fclose(f);

        UMNamedList *nl = [[UMNamedList alloc]initWithPath:@(s) name:@"jimtest"];
        [nl reload];
        [nl dump];
        [nl removeEntry:@"test2"];
        [nl dump];
    }
    return 0;
}

