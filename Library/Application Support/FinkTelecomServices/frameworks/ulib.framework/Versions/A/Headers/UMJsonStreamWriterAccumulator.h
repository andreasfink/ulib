//
//  UMJSonStreamWriterAccumulator.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import <ulib/UMJsonStreamWriter.h>
#import <ulib/UMObject.h>

@interface UMJsonStreamWriterAccumulator : UMObject <UMJsonStreamWriterDelegate>
{
    NSMutableData* data;
}
@property (readonly, strong) NSMutableData* data;

@end
