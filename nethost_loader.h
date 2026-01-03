#ifndef NETHOST_LOADER_H
#define NETHOST_LOADER_H

#include <QString>

// Forward declarations
struct hostfxr_handle;
typedef hostfxr_handle* hostfxr_handle_t;

// Function pointer type for RunAnalysis
// Matches C# signature: int RunAnalysis(string, string, string, out double, out double, bool, int)
typedef int (*run_analysis_fn)(
    const char* srcDsmDataset,
    const char* srcNdviDataset,
    const char* shapefileZip,
    double* fCov,
    double* meanNdvi,
    bool denoiseFlag,
    int areaThreshold
);

class NetHostLoader
{
public:
    NetHostLoader();
    ~NetHostLoader();
    
    // Initialize .NET runtime and load wrapper assembly
    bool initialize(const QString& assemblyPath, const QString& runtimeConfigPath);
    
    // Get function pointer for RunAnalysis
    run_analysis_fn getRunAnalysisFunction();
    
    // Cleanup
    void cleanup();
    
    // Get last error message
    QString getLastError() const { return m_lastError; }
    
private:
    hostfxr_handle_t m_hostfxrHandle;
    run_analysis_fn m_runAnalysisFunc;
    QString m_lastError;
    bool m_initialized;
    
    // Internal helpers
    bool loadHostFxr();
    bool initializeRuntime(const QString& runtimeConfigPath);
    bool loadAssemblyAndGetFunction(const QString& assemblyPath);
};

#endif // NETHOST_LOADER_H
