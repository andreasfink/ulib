//
//  UMJSonStreamWriterAccumulator.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//
//

#import "UMJsonStreamWriterAccumulator.h"


@implementation UMJsonStreamWriterAccumulator

@synthesize data;

- (id)init
{
    self = [super init];
    if(self)
    {
        data = [[NSMutableData alloc] initWithCapacity:8096u];
    }
    return self;
}


#pragma mark UMJsonStreamWriterDelegate

- (void)writer:(UMJsonStreamWriter *)writer appendBytes:(const void *)bytes length:(NSUInteger)length
{
    [data appendBytes:bytes length:length];
}

@end
