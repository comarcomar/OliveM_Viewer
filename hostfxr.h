// hostfxr.h - Minimal version for .NET 6 hosting
#ifndef __HOSTFXR_H__
#define __HOSTFXR_H__

#include <stdint.h>

#ifdef _WIN32
    typedef wchar_t char_t;
#else
    typedef char char_t;
#endif

#ifdef __cplusplus
extern "C" {
#endif

struct hostfxr_handle;
typedef struct hostfxr_handle* hostfxr_handle_t;

struct hostfxr_initialize_parameters
{
    size_t size;
    const char_t* host_path;
    const char_t* dotnet_root;
};

enum hostfxr_delegate_type
{
    hdt_com_activation = 0,
    hdt_load_in_memory_assembly = 1,
    hdt_winrt_activation = 2,
    hdt_com_register = 3,
    hdt_com_unregister = 4,
    hdt_load_assembly_and_get_function_pointer = 5,
    hdt_get_function_pointer = 6
};

#ifdef __cplusplus
}
#endif

#endif // __HOSTFXR_H__
