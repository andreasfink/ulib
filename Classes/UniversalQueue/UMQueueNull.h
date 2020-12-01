//
//  UMQueueNull.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import "UMQueueSingle.h"

/*!
 @class UMQueueNull
 @brief A UMQueueNull is a variant of UMQueueSingle where everything is discarded.
 Useful if you need to pass a queue but you dont really need the output.
 */

@interface UMQueueNull : UMQueueSingle

@end
