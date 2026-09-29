//
//  UMIPAddressList.h
//  ulib
//
//  Created by Andreas Fink on 11.03.2026.
//

#import <ulib/UMObject.h>
#import <ulib/UMSynchronizedArray.h>


@interface UMIPAddressList : UMObject
{
    UMSynchronizedArray *_entries;
}
@end

