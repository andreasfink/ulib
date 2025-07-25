//
//  UMDateTimeStuff.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import <ulib/framework.h>

NSString *UMTimeStampDTfromTime(time_t current);
time_t UMTimeFromTimestampDT(NSString *timestamp);
NSString *UMTimeStampDT(void);
NSString *UMTimeStampDTLocal(void);
