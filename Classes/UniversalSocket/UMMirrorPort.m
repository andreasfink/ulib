//
//  UMMirrorPort.m
//  ulib
//
//  Created by Andreas Fink on 09.05.22.
//  Copyright © 2022 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMMirrorPort.h"

@implementation UMMirrorPort

- (BOOL)openRaWSocket
{
    sock_r=socket(AF_PACKET,SOCK_RAW,htons(ETH_P_ALL));
    if(sock_r<0)
    {
        printf(error in socket\n);
        return -1;
    }
}
@end
