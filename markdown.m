#import <Foundation/Foundation.h>
#import "RenderMarkdown.h"
#include "discount-wrapper.h"

NSData* renderMarkdown(NSURL* url)
{
    NSString *styles = [[NSString alloc] initWithContentsOfURL:
                        [[NSBundle bundleWithIdentifier: @BUNDLEID]
                         URLForResource:@"styles" withExtension:@"css"]
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
		if (!output) {
			return nil;
		}
		NSOutput = [[NSString alloc] initWithBytesNoCopy:output length:strlen(output) encoding:NSUTF8StringEncoding freeWhenDone:YES];
	}
	
    if (!NSOutput) {
        return nil;
    }
    NSString *html = [[NSString alloc] initWithFormat:@"<!DOCTYPE html>"
                                                       "<meta charset=utf-8>"
                                                       "<style>%@</style>"
                                                       "<base href=\"%@\"/>"
                                                       "%@",
                                                       styles, url, NSOutput];

    return [html dataUsingEncoding:NSUTF8StringEncoding];
}
