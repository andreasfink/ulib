//
//  UMDirtyData.h
//  ulib
//
//  Created by Andreas Fink on 04.03.2025.
//

#import <ulib/UMDirtyObject.h>


#define UMDIRTY_DATA(a)     [[UMDirtyData alloc]initWithData:a]
<<<<<<< HEAD
#define SET_DIRTY_DATA(a,b)   \
if(a==NULL) \
{ \
    a = [[UMDirtyData alloc]initWithData:b]; \
}\
else\
{ \
    a.currentValue = b; \
}
=======
>>>>>>> bd8ae622abb748fc043563e7e90d719fe523addd

@interface UMDirtyData : UMDirtyObject


- (UMDirtyData *)initWithData:(NSData *)d;
- (UMDirtyData *)initWithString:(NSString *)s;

- (NSData *)data;
- (NSData *)previousData;
- (void)setData:(NSData *)d;

- (NSString *)stringValue;
- (NSString *)previousStringValue;
- (void)setStringValue:(NSString *)s;

- (UMDirtyData *)copyWithZone:(NSZone *)zone;

@end
