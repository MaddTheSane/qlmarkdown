//
//  GetMetadataForFile.h
//  QLMarkdown
//
//  Created by C.W. Betts on 9/8/15.
//
//

#ifndef GetMetadataForFile_h
#define GetMetadataForFile_h

#include <CoreFoundation/CFBase.h>

#ifndef __private_extern
#define __private_extern __attribute__((visibility("hidden")))
#endif

// The import function to be implemented in GetMetadataForFile.c
__private_extern Boolean GetMetadataForFile(void *thisInterface, CFMutableDictionaryRef attributes, CFStringRef contentTypeUTI, CFStringRef pathToFile);


#endif /* GetMetadataForFile_h */
