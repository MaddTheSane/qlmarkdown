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
    // Pull any available metadata from the file at the specified path
    // Return the attribute keys and attribute values in the dict
    // Return TRUE if successful, FALSE if there was no data provided
	// The path could point to either a Core Data store file in which
	// case we import the store's metadata, or it could point to a Core
	// Data external record file for a specific record instances

    Boolean ok = FALSE;
    @autoreleasepool {
        NSString *rawString;
        {
            NSData *aData = renderMarkdown([NSURL fileURLWithPath:(__bridge NSString*)pathToFile]);
            NSAttributedString *attrStr = [[NSAttributedString alloc] initWithHTML:aData documentAttributes:NULL];
            rawString = attrStr.string;
        }
    }
    
	// Return the status
    return ok;
}