//
//  UMStdIo.h
//  ulib
//
//  Created by Andreas Fink on 20.08.2026.
//

#import <Foundation/Foundation.h>


@interface UMStdIo : NSObject
{
    FILE *_in;
    FILE *_out;
    FILE *_err;
}

@property(readwrite,assign) FILE *in;
@property(readwrite,assign) FILE *out;
@property(readwrite,assign) FILE *err;

- (UMStdIo *)initWithInput:(FILE *)in output:(FILE *)out error:(FILE *)err;
- (UMStdIo *)init;

- (int)writeString:(NSString *)s;
- (int)writeStringNL:(NSString *)s;
- (int)writeErrorString:(NSString *)s;
- (int)writeErrorStringNL:(NSString *)s;
- (int)readShortLine:(NSString **)out;
@end

