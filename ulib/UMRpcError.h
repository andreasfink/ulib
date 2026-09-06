//
//  UMRpcError.h
//  ulibrpc
//
//  Created by Andreas Fink on 20.08.2026.
//

typedef enum UMRpcError
{
    UMRpcError_NOT_CONNECTED            = -3,
    UMRpcError_PENDING                  = -2,
    UMRpcError_UNDEFINED                = -1,
    UMRpcError_NO_ERROR                 =  0,
    UMRpcError_UNSUPPORTED_COMMAND      =  1,
    UMRpcError_PARAMETER_ERROR          =  2,
    UMRpcError_INVALID_STATE            =  3,
    UMRpcError_INVALID_INSTANCE         =  4,
    UMRpcError_NOT_AUTHORIZED           =  5,
    UMRpcError_API_VERSION_MISMATCH     =  6,
    UMRpcError_CONNECTION_ERROR         =  7,    
    UMRpcError_WRITE_FAILURE            = 101,
    UMRpcError_INSERT_FAILURE           = 102,
    UMRpcError_UPDATE_FAILURE           = 103,
    UMRpcError_LOAD_FAILURE             = 104,
    UMRpcError_NOT_FOUND                = 105,
    UMRpcError_DELETE_FAILURE           = 106,
    UMRpcError_NO_DB_SESSIONS_AVAILABLE = 107,
    UMRpcError_DB_ERROR                 = 108,
    UMRpcError_SYNTAX_ERROR             = 109,

} UMRpcError;
