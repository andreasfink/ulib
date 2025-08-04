//
//  UMDirtyString.h
//  ulib
//
//  Created by Andreas Fink on 04.03.2025.
//

#import <ulib/UMDirtyObject.h>

<<<<<<< HEAD
#define UMDIRTY_STRING(a)     [[UMDirtyString alloc]initWithString:(a)]

#define SET_DIRTY_STRING(a,b)   \
if(a==NULL) \
{ \
    a = [[UMDirtyString alloc]initWithString:(b)]; \
}\
else\
{ \
    a.currentValue = (b); \
}
=======
#define UMDIRTY_STRING(a)     [[UMDirtyString alloc]initWithString:a]
>>>>>>> bd8ae622abb748fc043563e7e90d719fe523addd

@interface UMDirtyString : UMDirtyObject

- (UMDirtyString *)initWithString:(NSString *)s;
- (NSString *)stringValue;
- (void)setStringValue:(NSString *)s;

- (UMDirtyString *)copyWithZone:(NSZone *)zone;

@end


