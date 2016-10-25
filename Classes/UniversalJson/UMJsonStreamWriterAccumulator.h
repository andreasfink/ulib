//
//  UMJSonStreamWriterAccumulator.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//
//

#import "UMJsonStreamWriter.h"
#import "UMObject.h"

@interface UMJsonStreamWriterAccumulator : UMObject <UMJsonStreamWriterDelegate>
{
    NSMutableData* data;
}
@property (readonly, strong) NSMutableData* data;

@end
