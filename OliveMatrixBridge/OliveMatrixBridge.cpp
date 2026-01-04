#include "OliveMatrixBridge.h"
#include <vcclr.h>
#include <msclr/marshal_cppstd.h>

using namespace System;
using namespace System::IO;
using namespace System::Reflection;
using namespace msclr::interop;

// Load and call OliveMatrixLibCore via C++/CLI
extern "C" OLIVEMATRIX_API int RunOliveMatrixAnalysis(
    const char* srcDsmDataset,
    const char* srcNdviDataset,
    const char* shapefileZip,
    double* fCov,
    double* meanNdvi,
    bool denoiseFlag,
    int areaThreshold)
{
    try
    {
        // Convert native strings to managed
        String^ dsmPath = marshal_as<String^>(srcDsmDataset);
        String^ ndviPath = marshal_as<String^>(srcNdviDataset);
        String^ shapePath = marshal_as<String^>(shapefileZip);
        
        Console::WriteLine("[Bridge] RunOliveMatrixAnalysis called");
        Console::WriteLine("[Bridge]   DSM: {0}", dsmPath);
        Console::WriteLine("[Bridge]   NDVI: {0}", ndviPath);
        Console::WriteLine("[Bridge]   Shapefile: {0}", shapePath);
        
        // Get directory of this DLL
        String^ currentDir = Path::GetDirectoryName(Assembly::GetExecutingAssembly()->Location);
        String^ coreLibPath = Path::Combine(currentDir, "OliveMatrixLibCore.dll");
        
        Console::WriteLine("[Bridge] Loading OliveMatrixLibCore from: {0}", coreLibPath);
        
        if (!File::Exists(coreLibPath))
        {
            Console::WriteLine("[Bridge] ERROR: OliveMatrixLibCore.dll not found");
            *fCov = 0.0;
            *meanNdvi = 0.0;
            return -1;
        }
        
        // Load assembly
        Assembly^ coreAssembly = Assembly::LoadFrom(coreLibPath);
        Type^ coreType = coreAssembly->GetType("OliveMatrixLib.OliveMatrixLibCore");
        
        if (coreType == nullptr)
        {
            Console::WriteLine("[Bridge] ERROR: Type OliveMatrixLib.OliveMatrixLibCore not found");
            *fCov = 0.0;
            *meanNdvi = 0.0;
            return -1;
        }
        
        // Create instance
        Object^ instance = Activator::CreateInstance(coreType);
        
        // Get RunAnalysis method
        MethodInfo^ method = coreType->GetMethod("RunAnalysis");
        if (method == nullptr)
        {
            Console::WriteLine("[Bridge] ERROR: RunAnalysis method not found");
            *fCov = 0.0;
            *meanNdvi = 0.0;
            return -1;
        }
        
        // Prepare parameters
        array<Object^>^ parameters = gcnew array<Object^>(7);
        parameters[0] = dsmPath;
        parameters[1] = ndviPath;
        parameters[2] = shapePath;
        parameters[3] = 0.0;  // out fCov
        parameters[4] = 0.0;  // out meanNdvi
        parameters[5] = denoiseFlag;
        parameters[6] = areaThreshold;
        
        // Invoke
        Console::WriteLine("[Bridge] Calling OliveMatrixLibCore.RunAnalysis...");
        Object^ result = method->Invoke(instance, parameters);
        
        // Extract out parameters
        *fCov = Convert::ToDouble(parameters[3]);
        *meanNdvi = Convert::ToDouble(parameters[4]);
        
        int returnCode = safe_cast<int>(result);
        
        Console::WriteLine("[Bridge] Analysis complete. Result: {0}, fCov: {1}, meanNdvi: {2}", 
            returnCode, *fCov, *meanNdvi);
        
        return returnCode;
    }
    catch (Exception^ ex)
    {
        Console::WriteLine("[Bridge] EXCEPTION: {0}", ex->Message);
        Console::WriteLine("[Bridge] Stack trace: {0}", ex->StackTrace);
        
        if (ex->InnerException != nullptr)
        {
            Console::WriteLine("[Bridge] Inner exception: {0}", ex->InnerException->Message);
        }
        
        *fCov = 0.0;
        *meanNdvi = 0.0;
        return -1;
    }
}
