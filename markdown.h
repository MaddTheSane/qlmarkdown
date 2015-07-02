#import <Foundation/Foundation.h>

#ifndef __private_extern
#define __private_extern __attribute__((visibility("hidden")))
#endif

__private_extern NSData* __nullable renderMarkdown(NSURL* __nonnull url);
