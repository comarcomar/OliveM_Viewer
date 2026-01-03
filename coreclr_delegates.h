// coreclr_delegates.h - Minimal version for .NET 6 hosting
#ifndef __CORECLR_DELEGATES_H__
#define __CORECLR_DELEGATES_H__

#include <stdint.h>

#ifdef _WIN32
    typedef wchar_t char_t;
#else
    typedef char char_t;
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef int32_t (*load_assembly_and_get_function_pointer_fn)(
    const char_t* assembly_path,
    const char_t* type_name,
    const char_t* method_name,
    const char_t* delegate_type_name,
    void* reserved,
    void** delegate
);

#ifdef __cplusplus
}
#endif

#endif // __CORECLR_DELEGATES_H__
