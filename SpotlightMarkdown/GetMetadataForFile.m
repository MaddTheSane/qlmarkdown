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

static BOOL GetMetadataForNSURL(void *thisInterface, NSMutableDictionary *attributes, NSString *contentTypeUTI, NSURL *URLToFile);

Boolean GetMetadataForFile(void *thisInterface, CFMutableDictionaryRef attributes, CFStringRef contentTypeUTI, CFStringRef pathToFile)
{
    @autoreleasepool {
        return GetMetadataForNSURL(thisInterface, (__bridge NSMutableDictionary *)(attributes), (__bridge NSString *)(contentTypeUTI), [NSURL fileURLWithPath:(__bridge NSString *)(pathToFile)]);
    }
}

static BOOL GetMetadataForNSURL(void *thisInterface, NSMutableDictionary *attributes, NSString *contentTypeUTI, NSURL *URLToFile){
    BOOL ok = NO;
        NSString *rawString = nil;
        NSData *aData;
        do {
            aData = renderMarkdown(URLToFile);
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
            attributes[(NSString*)kMDItemTextContent] = rawString;
            if (&kMDItemHTMLContent) {
                NSString *htmlStr = [[NSString alloc] initWithData:aData encoding:NSUTF8StringEncoding];
                attributes[(NSString*)kMDItemHTMLContent] = htmlStr;
            }
            ok = YES;
        }
    
	// Return the status
    return ok;
}
