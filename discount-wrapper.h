
#ifndef __private_extern
#define __private_extern extern __attribute__((visibility("hidden")))
#endif

__private_extern char* convert_markdown_to_string(const char *str);
