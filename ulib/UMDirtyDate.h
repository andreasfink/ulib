//
//  UMDirtyDate.h
//  ulib
//
//  Created by Andreas Fink on 04.03.2025.
//

#import <ulib/UMDirtyObject.h>

#define UMDIRTY_DATE(a)     [[UMDirtyDate alloc]initWithDate:a]
<<<<<<< HEAD
#define SET_DIRTY_DATE(a,b)   \
if(a==NULL) \
{ \
    a = [[UMDirtyDate alloc]initWithDate:b]; \
}\
else\
{ \
    a.currentValue = b; \
}
=======
>>>>>>> origin/release-2.1

@interface UMDirtyDate : UMDirtyObject

- (UMDirtyDate *)initWithDate:(NSDate *)d;
- (UMDirtyDate *)initWithString:(NSString *)s;

- (NSDate *)dateValue;
- (NSDate *)previousDateValue;
- (void)setDateValue:(NSDate *)d;

- (NSString *)stringValue;
- (NSString *)previousStringValue;
- (void)setStringValue:(NSString *)s;

- (UMDirtyDate *)copyWithZone:(NSZone *)zone;

@end

