#import <QuickLook/QuickLook.h>
#import <Cocoa/Cocoa.h>
#include "markdown.h"

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   -------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview,
							   CFURLRef url, CFStringRef contentTypeUTI, 
							   CFDictionaryRef options)
{
    NSData *data = renderMarkdown((__bridge NSURL*) url);

    if (data) {
		NSDictionary *props = @{};
        QLPreviewRequestSetDataRepresentation(preview, (__bridge CFDataRef)data, kUTTypeHTML, (__bridge CFDictionaryRef)props);
    }

    return noErr;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
