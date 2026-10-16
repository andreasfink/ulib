//
//  main.m
//  webtest
//
//  Created by Andreas Fink on 15.10.2026.
//

#import <ulib/ulib.h>
#import <ulib/UMWebObject_all.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool
    {
        UMWebObjectHTML *document = [[UMWebObjectHTML alloc]init];
        UMWebObjectHEAD *head = [[UMWebObjectHEAD alloc]init];
        head.tag = @"head";
        
        UMWebObject *body = [[UMWebObjectBODY alloc]init];
        body.tag = @"body";
        
        UMWebObject *title = [[UMWebObjectTITLE alloc]init];
        title.tag = @"title";
        title.content = @"this is the title";
        title.noWrap=YES;
        [head addChild:title];
        
        UMWebObjectP *title = [[UMWebObjectP alloc]init];

        document.children = @[head,body];
        NSString *html = [document htmlString:YES ident:0 flags:0];
        NSLog(@"HMTL Code:\n%@\n",html);
    }
    return EXIT_SUCCESS;
}
