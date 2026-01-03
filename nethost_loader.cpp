#include "nethost_loader.h"
#include <QDebug>
#include <QDir>
#include <QFileInfo>

#ifdef Q_OS_WIN
#include <windows.h>
#endif

// .NET hosting headers (minimal versions)
#include "nethost.h"
#include "hostfxr.h"
#include "coreclr_delegates.h"

// Global function pointers for hostfxr
typedef int32_t (*hostfxr_initialize_for_runtime_config_fn)(
    const char_t* runtime_config_path,
    const struct hostfxr_initialize_parameters* parameters,
    hostfxr_handle_t* host_context_handle
);

typedef int32_t (*hostfxr_get_runtime_delegate_fn)(
    const hostfxr_handle_t host_context_handle,
    enum hostfxr_delegate_type type,
    void** delegate
);

typedef int32_t (*hostfxr_close_fn)(hostfxr_handle_t host_context_handle);

static hostfxr_initialize_for_runtime_config_fn g_hostfxr_initialize = nullptr;
static hostfxr_get_runtime_delegate_fn g_hostfxr_get_delegate = nullptr;
static hostfxr_close_fn g_hostfxr_close = nullptr;

NetHostLoader::NetHostLoader()
    : m_hostfxrHandle(nullptr)
    , m_runAnalysisFunc(nullptr)
    , m_initialized(false)
{
}

NetHostLoader::~NetHostLoader()
{
    cleanup();
}

bool NetHostLoader::loadHostFxr()
{
    // Get path to hostfxr library
    char_t buffer[MAX_PATH];
    size_t buffer_size = sizeof(buffer) / sizeof(char_t);
    
    int rc = get_hostfxr_path(buffer, &buffer_size, nullptr);
    if (rc != 0)
    {
        m_lastError = QString("Failed to get hostfxr path. Error code: %1").arg(rc);
        qWarning() << m_lastError;
        return false;
    }
    
    QString hostfxrPath = QString::fromWCharArray(buffer);
    qDebug() << "[NetHost] Found hostfxr at:" << hostfxrPath;
    
    // Load hostfxr library
#ifdef Q_OS_WIN
    HMODULE lib = LoadLibraryW(buffer);
#else
    void* lib = dlopen(hostfxrPath.toUtf8().constData(), RTLD_LAZY);
#endif
    
    if (!lib)
    {
        m_lastError = "Failed to load hostfxr library";
        qWarning() << m_lastError;
        return false;
    }
    
    // Get function pointers
#ifdef Q_OS_WIN
    g_hostfxr_initialize = (hostfxr_initialize_for_runtime_config_fn)
        GetProcAddress(lib, "hostfxr_initialize_for_runtime_config");
    g_hostfxr_get_delegate = (hostfxr_get_runtime_delegate_fn)
        GetProcAddress(lib, "hostfxr_get_runtime_delegate");
    g_hostfxr_close = (hostfxr_close_fn)
        GetProcAddress(lib, "hostfxr_close");
#else
    g_hostfxr_initialize = (hostfxr_initialize_for_runtime_config_fn)
        dlsym(lib, "hostfxr_initialize_for_runtime_config");
    g_hostfxr_get_delegate = (hostfxr_get_runtime_delegate_fn)
        dlsym(lib, "hostfxr_get_runtime_delegate");
    g_hostfxr_close = (hostfxr_close_fn)
        dlsym(lib, "hostfxr_close");
#endif
    
    if (!g_hostfxr_initialize || !g_hostfxr_get_delegate || !g_hostfxr_close)
    {
        m_lastError = "Failed to get hostfxr function pointers";
        qWarning() << m_lastError;
        return false;
    }
    
    qDebug() << "[NetHost] Successfully loaded hostfxr functions";
    return true;
}

bool NetHostLoader::initializeRuntime(const QString& runtimeConfigPath)
{
    if (!g_hostfxr_initialize)
    {
        m_lastError = "hostfxr not loaded";
        return false;
    }
    
    std::wstring configPath = runtimeConfigPath.toStdWString();
    
    qDebug() << "[NetHost] Initializing .NET runtime with config:" << runtimeConfigPath;
    
    int rc = g_hostfxr_initialize(
        configPath.c_str(),
        nullptr,
        &m_hostfxrHandle
    );
    
    if (rc != 0 || m_hostfxrHandle == nullptr)
    {
        m_lastError = QString("Failed to initialize .NET runtime. Error code: %1").arg(rc);
        qWarning() << m_lastError;
        return false;
    }
    
    qDebug() << "[NetHost] Successfully initialized .NET runtime";
    return true;
}

bool NetHostLoader::loadAssemblyAndGetFunction(const QString& assemblyPath)
{
    if (!m_hostfxrHandle || !g_hostfxr_get_delegate)
    {
        m_lastError = "Runtime not initialized";
        return false;
    }
    
    // Get load_assembly_and_get_function_pointer delegate
    void* load_assembly_fn_ptr = nullptr;
    int rc = g_hostfxr_get_delegate(
        m_hostfxrHandle,
        hdt_load_assembly_and_get_function_pointer,
        &load_assembly_fn_ptr
    );
    
    if (rc != 0 || load_assembly_fn_ptr == nullptr)
    {
        m_lastError = QString("Failed to get load_assembly delegate. Error code: %1").arg(rc);
        qWarning() << m_lastError;
        return false;
    }
    
    typedef int (*load_assembly_and_get_function_pointer_fn)(
        const char_t* assembly_path,
        const char_t* type_name,
        const char_t* method_name,
        const char_t* delegate_type_name,
        void* reserved,
        void** delegate
    );
    
    auto load_assembly = (load_assembly_and_get_function_pointer_fn)load_assembly_fn_ptr;
    
    // Load OliveMatrixWrapper assembly and call GetRunAnalysisFunctionPointer
    std::wstring assembly = assemblyPath.toStdWString();
    std::wstring typeName = L"OliveMatrixWrapper.NativeInterop, OliveMatrixWrapper";
    std::wstring methodName = L"GetRunAnalysisFunctionPointer";
    
    qDebug() << "[NetHost] Loading assembly:" << assemblyPath;
    qDebug() << "[NetHost] Type: OliveMatrixWrapper.NativeInterop, OliveMatrixWrapper";
    qDebug() << "[NetHost] Method: GetRunAnalysisFunctionPointer";
    
    // This method returns an IntPtr (function pointer)
    typedef void* (*get_function_pointer_fn)();
    get_function_pointer_fn getFunctionPtr = nullptr;
    
    rc = load_assembly(
        assembly.c_str(),
        typeName.c_str(),
        methodName.c_str(),
        nullptr,
        nullptr,
        (void**)&getFunctionPtr
    );
    
    if (rc != 0 || getFunctionPtr == nullptr)
    {
        m_lastError = QString("Failed to load assembly or get GetRunAnalysisFunctionPointer. Error code: %1").arg(rc);
        qWarning() << m_lastError;
        return false;
    }
    
    qDebug() << "[NetHost] Calling GetRunAnalysisFunctionPointer...";
    
    // Call GetRunAnalysisFunctionPointer() which returns the actual function pointer
    void* functionPointer = getFunctionPtr();
    
    if (functionPointer == nullptr)
    {
        m_lastError = "GetRunAnalysisFunctionPointer returned null";
        qWarning() << m_lastError;
        return false;
    }
    
    m_runAnalysisFunc = (run_analysis_fn)functionPointer;
    
    qDebug() << "[NetHost] Successfully obtained RunAnalysis function pointer";
    return true;
}

bool NetHostLoader::initialize(const QString& assemblyPath, const QString& runtimeConfigPath)
{
    qDebug() << "=== Initializing .NET Host ===";
    
    // Verify files exist
    if (!QFile::exists(assemblyPath))
    {
        m_lastError = QString("Assembly not found: %1").arg(assemblyPath);
        qWarning() << m_lastError;
        return false;
    }
    
    if (!QFile::exists(runtimeConfigPath))
    {
        m_lastError = QString("Runtime config not found: %1").arg(runtimeConfigPath);
        qWarning() << m_lastError;
        return false;
    }
    
    // Load hostfxr
    if (!loadHostFxr())
        return false;
    
    // Initialize runtime
    if (!initializeRuntime(runtimeConfigPath))
        return false;
    
    // Load assembly and get function pointer
    if (!loadAssemblyAndGetFunction(assemblyPath))
    {
        cleanup();
        return false;
    }
    
    m_initialized = true;
    qDebug() << "=== .NET Host Initialized Successfully ===";
    return true;
}

run_analysis_fn NetHostLoader::getRunAnalysisFunction()
{
    return m_runAnalysisFunc;
}

void NetHostLoader::cleanup()
{
    if (m_hostfxrHandle && g_hostfxr_close)
    {
        qDebug() << "[NetHost] Closing .NET runtime";
        g_hostfxr_close(m_hostfxrHandle);
        m_hostfxrHandle = nullptr;
    }
    
    m_runAnalysisFunc = nullptr;
    m_initialized = false;
}
