//
//  main.m
//  webtest
//
//  Created by Andreas Fink on 15.10.2026.
//

#import <ulib/ulib.h>
#import <ulib/UMWebObject.h>
#import <ulib/UMWebObjectP.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool
    {
        UMWebObject *document = [[UMWebObject alloc]init];
        document.tag = @"html";

        UMWebObject *head = [[UMWebObject alloc]init];
        head.tag = @"head";
        
        UMWebObject *body = [[UMWebObject alloc]init];
        body.tag = @"body";
        
        UMWebObject *title = [[UMWebObject alloc]init];
        title.tag = @"title";
        title.content = @"this is the title";
        title.noWrap=YES;
        [head addChild:title];
        
        UMWebObjectP *title = [[UMWebObject alloc]init];

        document.children = @[head,body];
        NSString *html = [document htmlString:YES ident:0 flags:0];
        NSLog(@"HMTL Code:\n%@\n",html);
    }
    return EXIT_SUCCESS;
}
