//
//  GetMetadataForFile.m
//  SpotlightMarkdown
//
//  Created by C.W. Betts on 9/8/15.
//
//

#include <CoreServices/CoreServices.h>
#include <CoreFoundation/CoreFoundation.h>
#import <AppKit/AppKit.h>
#include "GetMetadataForFile.h"
#import "RenderMarkdown.h"

//==============================================================================
//
//	Get metadata attributes from document files
//
//	The purpose of this function is to extract useful information from the
//	file formats for your document, and set the values into the attribute
//  dictionary for Spotlight to include.
//
//==============================================================================

Boolean GetMetadataForFile(void *thisInterface, CFMutableDictionaryRef attributes, CFStringRef contentTypeUTI, CFStringRef pathToFile)
{
    Boolean ok = FALSE;
    @autoreleasepool {
        NSString *rawString = nil;
        NSMutableDictionary *NSattribs = (__bridge NSMutableDictionary*)attributes;
        NSData *aData;
        do {
            aData = renderMarkdown([NSURL fileURLWithPath:(__bridge NSString*)pathToFile]);
            if (!aData) {
                break;
            }
            NSAttributedString *attrStr = [[NSAttributedString alloc] initWithHTML:aData documentAttributes:NULL];
            if (!attrStr) {
                break;
            }
            rawString = attrStr.string;
        } while(0);
        if (rawString) {
            NSattribs[(NSString*)kMDItemTextContent] = rawString;
            if (&kMDItemHTMLContent) {
                NSString *htmlStr = [[NSString alloc] initWithData:aData encoding:NSUTF8StringEncoding];
                NSattribs[(NSString*)kMDItemHTMLContent] = htmlStr;
            }
            ok = TRUE;
        }
    }
    
	// Return the status
    return ok;
}
