// nethost.h - Minimal version for .NET 6 hosting
#ifndef __NETHOST_H__
#define __NETHOST_H__

#include <stdint.h>

#ifdef _WIN32
    typedef wchar_t char_t;
#else
    typedef char char_t;
#endif

#ifdef __cplusplus
extern "C" {
#endif

// Get the path to the hostfxr library
int32_t get_hostfxr_path(
    char_t* buffer,
    size_t* buffer_size,
    const void* parameters
);

#ifdef __cplusplus
}
#endif

#endif // __NETHOST_H__
