#import <Foundation/Foundation.h>
#import "markdown.h"
#include "discount-wrapper.h"

NSData* renderMarkdown(NSURL* url)
{
    NSString *styles = [[NSString alloc] initWithContentsOfFile:[[NSBundle bundleWithIdentifier: @"com.fiatdev.QLMarkdown"]
                                                           pathForResource:@"styles" ofType:@"css"]
                                                 encoding:NSUTF8StringEncoding
                                                    error:nil];

    NSStringEncoding usedEncoding = 0;

    NSString *source = [[NSString alloc] initWithContentsOfURL:url usedEncoding:&usedEncoding error:NULL];

    if (usedEncoding == 0) {
        NSLog(@"Wasn't able to determine encoding for file “%@”", [url path]);
    }

    NSString *NSOutput;
    {
    char *output = convert_markdown_to_string([source UTF8String]);
        NSOutput = [[NSString alloc] initWithBytesNoCopy:output length:strlen(output) encoding:NSUTF8StringEncoding freeWhenDone:YES];
    }
    if (!NSOutput) {
        return nil;
    }
    NSString *html = [NSString stringWithFormat:@"<!DOCTYPE html>"
                                                 "<meta charset=utf-8>"
                                                 "<style>%@</style>"
                                                 "<base href=\"%@\"/>"
                                                 "%@",
                                                 styles, url, NSOutput];

    return [html dataUsingEncoding:NSUTF8StringEncoding];
}
