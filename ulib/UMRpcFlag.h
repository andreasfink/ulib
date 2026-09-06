//
//  UMRpcFlags.h
//  ulibrpc
//
//  Created by Andreas Fink on 21.08.2026.
//

typedef enum UMRpcFlag
{
    UMRpcFlag_IS_RESPONSE           = 0x01,
    UMRpcFlag_CLOSING_CONNECTION    = 0x02,
} UMRpcFlag;
