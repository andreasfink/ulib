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
        [document addChild:head];
        UMWebObjectTITLE *title = [[UMWebObjectTITLE alloc]initWithString:@"Welcome"];
        [head addChild:title];

        UMWebObject *body = [[UMWebObjectBODY alloc]init];
        [document addChild:body];
        
        UMWebObjectH1 *h1 = [[UMWebObjectH1 alloc]initWithString:@"A Title"];
        [h1 setAttribute:@"class" value:@"myclass"];
        [body addChild:h1];
        
        UMWebObjectP *p = [[UMWebObjectP alloc]initWithString:@"this is the content"];
        UMWebObjectBR *br = [[UMWebObjectBR alloc]init];
        
        [p addChild:br];
        [p addText:@"more text"];

        [body addChild:p];


        UMWebObjectA *a = [[UMWebObjectA alloc]initWithURL:@"https://example.com"
                                                      text:@"a link"];
        
        [body addChild:a];

        UMWebObjectP *p2 = [[UMWebObjectP alloc]initWithString:@"Another paragraph"];
        [body addChild:p2];

        

        NSString *html = [document htmlString:YES ident:0 flags:0];
        NSString *html2 = [document htmlString:NO ident:0 flags:0];
        NSLog(@"HMTL Code:\n%@\n",html);
        NSLog(@"HMTL Code2:\n%@\n",html2);
    }
    return EXIT_SUCCESS;
}
