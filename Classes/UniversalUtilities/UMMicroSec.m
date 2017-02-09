//
//  UMMicroSec.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import "UMMicroSec.h"
#include <sys/time.h>

UMMicroSec ulib_microsecondTime(void)
{
    struct	timeval  tp;
    struct	timezone tzp;
    gettimeofday(&tp, &tzp);
    return (UMMicroSec)tp.tv_sec * 1000000ULL + ((UMMicroSec)tp.tv_usec);
}
