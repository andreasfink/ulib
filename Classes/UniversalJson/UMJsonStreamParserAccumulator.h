//
//  UMJSonStreamParserAccumulator.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "UMJsonStreamParserAdapter.h"

@interface UMJsonStreamParserAccumulator : NSObject <UMJsonStreamParserAdapterDelegate>
{
    id value;
}

@property (readwrite,strong) id value;

@end
