//
//  UMRegexMatch.h
//  ulib
//
//  Created by Andreas Fink on 08.07.16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"

@interface UMRegexMatch : UMObject
{
    ssize_t  start;
    ssize_t  end;
    NSString *matched;
}

@property(readwrite,assign) ssize_t  start;
@property(readwrite,assign) ssize_t  end;
@property(readwrite,strong) NSString *matched;

@end
