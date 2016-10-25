//
//  UMConfigLocation.h
//  ulib
//
//  Created by Andreas Fink on 16.12.11.
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#import "UMObject.h"

@interface UMConfigLocation : UMObject
{  
    NSString *filename; 
    long line_no; 
    NSString *line; 
}; 

@property(readwrite,strong) NSString *filename; 
@property(readwrite,assign) long line_no; 
@property(readwrite,strong) NSString *line; 

@end
