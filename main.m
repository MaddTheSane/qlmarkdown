//==============================================================================
//
//	DO NO MODIFY THE CONTENT OF THIS FILE
//
//	This file contains the generic CFPlug-in code necessary for your generator
//	To complete your generator implement the function in GenerateThumbnailForURL/GeneratePreviewForURL.c
//
//==============================================================================



#include <CoreFoundation/CoreFoundation.h>
#include <CoreFoundation/CFPlugInCOM.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import <Foundation/Foundation.h>

#import "QLMarkdown-Swift.h"

// -----------------------------------------------------------------------------
//	constants
// -----------------------------------------------------------------------------

// Don't modify this line
#define PLUGIN_ID "984AED87-72B9-4060-B7BC-935561C2221B"

// -----------------------------------------------------------------------------
//  QuickLookGeneratorPluginFactory
// -----------------------------------------------------------------------------
void *QuickLookGeneratorPluginFactory(CFAllocatorRef allocator,CFUUIDRef typeID)
{
    return [QLMarkDownGenerator quickLookGeneratorPluginFactory: allocator typeID: typeID];
}
