//
//  UMDeprecatedMacros.h
//  ulib
//
//  Created by Andreas Fink on 03.11.2025.
//

#ifndef UMDeprecatedMacros_h
#define UMDeprecatedMacros_h


#define UM_WEAK_IMPORT_ATTRIBUTE __attribute__((weak_import))
#define UM_DEPRECATED_ATTRIBUTE        __attribute__((deprecated))
#define UM_DEPRECATED_MSG_ATTRIBUTE(s) __attribute__((deprecated(s)))

#endif /* UMDeprecatedMacros_h */
