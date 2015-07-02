#include <QuickLook/QuickLook.h>
#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "markdown.h"
#include "main.h"

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as
   possible
   -------------------------------------------------------------------------- */

//The minimum aspect ratio (width / height) of a thumbnail.
#define MINIMUM_ASPECT_RATIO (1.0/2.0)


OSStatus GenerateThumbnailForURL(void *thisInterface, 
								 QLThumbnailRequestRef thumbnail, 
								 CFURLRef url, CFStringRef contentTypeUTI, 
								 CFDictionaryRef options, CGSize maxSize)
{
    @autoreleasepool {
    NSData *data = renderMarkdown((__bridge NSURL*) url);

    if (data) {
		NSRect viewRect = NSMakeRect(0.0, 0.0, 600.0, 800.0);
		CGFloat scale = maxSize.height / 800.0;
		NSSize scaleSize = NSMakeSize(scale, scale);
		CGSize thumbSize = NSMakeSize((maxSize.width * (600.0/800.0)),
                                      maxSize.height);

        WebView* webView = [[WebView alloc] initWithFrame: viewRect];
		[webView scaleUnitSquareToSize: scaleSize];
        webView.mainFrame.frameView.allowsScrolling = NO;
        [webView.mainFrame loadData: data
                           MIMEType: @"text/html"
                   textEncodingName: @"utf-8"
                            baseURL: nil];

		while([webView isLoading]) {
			CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, true);
		}

		[webView display];

		CGContextRef context = 
			QLThumbnailRequestCreateContext(thumbnail, thumbSize, false, NULL);

		if (context) {
			NSGraphicsContext* nsContext = 
						[NSGraphicsContext
							graphicsContextWithGraphicsPort: (void*) context 
													flipped: webView.flipped];

			[webView displayRectIgnoringOpacity: webView.bounds
									  inContext: nsContext];

			QLThumbnailRequestFlushContext(thumbnail, context);

			CFRelease(context);
		}
    }

    return noErr;
    }
}

void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail)
{
    // implement only if supported
}
