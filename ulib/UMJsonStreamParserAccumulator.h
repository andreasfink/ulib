//
//  UMJSonStreamParserAccumulator.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import <ulib/framework.h>
#import <ulib/UMJsonStreamParserAdapter.h>

@interface UMJsonStreamParserAccumulator : NSObject <UMJsonStreamParserAdapterDelegate>
{
    id value;
}

@property (readwrite,strong) id value;

@end
