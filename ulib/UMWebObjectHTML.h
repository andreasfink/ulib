//
//  UMWebObjectHTML.h
//  ulib
//
//  Created by Andreas Fink on 16.10.2026.
//

#import <ulib/UMWebObject.h>
@class UMWebObjectBODY;
@class UMWebObjectHEAD;
@interface UMWebObjectHTML : UMWebObject
{
    UMWebObjectBODY *_body;
    UMWebObjectHEAD *_head;
}

@property(readonly,strong)  UMWebObjectBODY *body;
@property(readonly,strong)  UMWebObjectHEAD *head;

@end

