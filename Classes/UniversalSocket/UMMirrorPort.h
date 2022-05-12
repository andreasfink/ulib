//
//  UMMirrorPort.h
//  ulib
//
//  Created by Andreas Fink on 09.05.22.
//  Copyright © 2022 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>


@interface UMMirrorPort : UMObject
{
    NSString *_interfaceName;
    int       _raw_socket;
}
@end

