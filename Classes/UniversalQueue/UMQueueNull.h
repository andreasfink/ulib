//
//  UMQueueNull.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//
//

#import "UMQueue.h"

/*!
 @class UMQueueNull
 @brief A UMQueueNull is a variant of UMQueue where everything is discarded.
 Useful if you need to pass a queue but you dont really need the output.
 */

@interface UMQueueNull : UMQueue

@end
