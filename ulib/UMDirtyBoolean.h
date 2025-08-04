//
//  UMDirtyBoolean.h
//  ulib
//
//  Created by Andreas Fink on 04.03.2025.
//

#import <ulib/UMDirtyObject.h>

#define UMDIRTY_BOOLEAN(a)     [[UMDirtyBoolean alloc]initWithBoolean:a]
#define UMDIRTY_YES            [[UMDirtyBoolean alloc]initWithBoolean:YES]
#define UMDIRTY_NO             [[UMDirtyBoolean alloc]initWithBoolean:NO]

<<<<<<< HEAD
#define SET_DIRTY_BOOLEAN(a,b)   \
if(a==NULL) \
{ \
    a = [[UMDirtyBoolean alloc]initWithBoolean:b]; \
}\
else\
{ \
    a.currentValue = b; \
}

=======
>>>>>>> bd8ae622abb748fc043563e7e90d719fe523addd
@interface UMDirtyBoolean : UMDirtyObject
{
    
}

- (UMDirtyBoolean *)initWithNumber:(NSNumber *)n;
- (UMDirtyBoolean *)initWithBoolean:(BOOL)b;
- (UMDirtyBoolean *)initWithString:(NSString *)s;

- (NSNumber *)number;
- (NSNumber *)previousNumber;
- (void)setNumber:(NSNumber *)n;

- (BOOL)booleanValue;
- (BOOL)previousBooleanValue;
- (void)setBooleanValue:(BOOL)newValue;

- (NSString *)stringValue;
- (NSString *)previousStringValue;
- (void)setStringValue:(NSString *)s;
- (UMDirtyBoolean *)copyWithZone:(NSZone *)zone;

@end
