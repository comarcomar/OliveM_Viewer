#include "OliveMatrixBridge.h"
#include <vcclr.h>
#include <msclr/marshal_cppstd.h>

using namespace System;
using namespace System::IO;
using namespace System::Reflection;
using namespace System::Runtime::InteropServices;
using namespace msclr::interop;

// Load and call OliveMatrixLibCore via C++/CLI
extern "C" OLIVEMATRIX_API int RunOliveMatrixAnalysis(
    const wchar_t* srcDsmDataset,
    const wchar_t* srcNdviDataset,
    const wchar_t* shapefileZip,
    double* fCov,
    double* meanNdvi,
    bool denoiseFlag,
    int areaThreshold)
{
    try
    {
        // Convert wchar_t* to managed String^ using marshal
        String^ dsmPath = Marshal::PtrToStringUni(IntPtr((void*)srcDsmDataset));
        String^ ndviPath = Marshal::PtrToStringUni(IntPtr((void*)srcNdviDataset));
        String^ shapePath = Marshal::PtrToStringUni(IntPtr((void*)shapefileZip));
        
        Console::WriteLine("[Bridge] RunOliveMatrixAnalysis called");
        Console::WriteLine("[Bridge] Received parameters:");
        Console::WriteLine("[Bridge]   DSM: '{0}'", dsmPath);
        Console::WriteLine("[Bridge]   NDVI: '{0}'", ndviPath);
        Console::WriteLine("[Bridge]   Shapefile: '{0}'", shapePath);
        
        // Check if strings are empty
        if (String::IsNullOrEmpty(dsmPath))
        {
            Console::WriteLine("[Bridge] ERROR: DSM path is null or empty!");
            *fCov = 0.0;
            *meanNdvi = 0.0;
            return -1;
        }
        
        if (String::IsNullOrEmpty(ndviPath))
        {
            Console::WriteLine("[Bridge] ERROR: NDVI path is null or empty!");
            *fCov = 0.0;
            *meanNdvi = 0.0;
            return -1;
        }
        
        // Get bridge directory (where OliveMatrixBridge.dll is)
        // All OliveMatrixLibCore files are deployed to same directory
        String^ bridgeDir = Path::GetDirectoryName(Assembly::GetExecutingAssembly()->Location);
        String^ coreLibPath = Path::Combine(bridgeDir, "OliveMatrixLibCore.dll");
        
        Console::WriteLine("[Bridge] Bridge directory: {0}", bridgeDir);
        Console::WriteLine("[Bridge] Looking for OliveMatrixLibCore.dll: {0}", coreLibPath);
        
        if (!File::Exists(coreLibPath))
        {
            Console::WriteLine("[Bridge] ERROR: OliveMatrixLibCore.dll not found");
            Console::WriteLine("[Bridge] Ensure OliveMatrixLibCore is deployed to app directory");
            *fCov = 0.0;
            *meanNdvi = 0.0;
            return -1;
        }
        
        // Load assembly from same directory as bridge
        Console::WriteLine("[Bridge] Loading OliveMatrixLibCore assembly...");
        Assembly^ coreAssembly = Assembly::LoadFrom(coreLibPath);
        
        // Get Processing type
        Type^ coreType = coreAssembly->GetType("OliveMatrixLibCore.Processing");
        
        if (coreType == nullptr)
        {
            Console::WriteLine("[Bridge] ERROR: Type OliveMatrixLibCore.Processing not found");
            *fCov = 0.0;
            *meanNdvi = 0.0;
            return -1;
        }
        
        Console::WriteLine("[Bridge] Found type: OliveMatrixLibCore.Processing");
        
        // Create instance - GdalConfiguration will find gdal/ in same directory
        Console::WriteLine("[Bridge] Creating Processing instance...");
        Object^ instance = Activator::CreateInstance(coreType);
        
        if (instance == nullptr)
        {
            Console::WriteLine("[Bridge] ERROR: Failed to create Processing instance");
            *fCov = 0.0;
            *meanNdvi = 0.0;
            return -1;
        }
        
        // Get RunAnalysis method
        MethodInfo^ method = coreType->GetMethod("RunAnalysis");
        if (method == nullptr)
        {
            Console::WriteLine("[Bridge] ERROR: RunAnalysis method not found in Processing");
            *fCov = 0.0;
            *meanNdvi = 0.0;
            return -1;
        }
        
        Console::WriteLine("[Bridge] Found RunAnalysis method");
        
        // Prepare parameters
        array<Object^>^ parameters = gcnew array<Object^>(7);
        parameters[0] = dsmPath;
        parameters[1] = ndviPath;
        parameters[2] = shapePath;
        parameters[3] = 0.0;  // out fCov
        parameters[4] = 0.0;  // out meanNdvi
        parameters[5] = denoiseFlag;
        parameters[6] = areaThreshold;
        
        // DEBUG: Verify parameters array
        Console::WriteLine("[Bridge] Parameters prepared:");
        Console::WriteLine("[Bridge]   Param[0] type: {0}, value: '{1}'", parameters[0]->GetType()->Name, parameters[0]);
        Console::WriteLine("[Bridge]   Param[1] type: {0}, value: '{1}'", parameters[1]->GetType()->Name, parameters[1]);
        Console::WriteLine("[Bridge]   Param[2] type: {0}, value: '{1}'", parameters[2]->GetType()->Name, parameters[2]);
        Console::WriteLine("[Bridge]   Param[3] type: {0}, value: {1}", parameters[3]->GetType()->Name, parameters[3]);
        Console::WriteLine("[Bridge]   Param[4] type: {0}, value: {1}", parameters[4]->GetType()->Name, parameters[4]);
        Console::WriteLine("[Bridge]   Param[5] type: {0}, value: {1}", parameters[5]->GetType()->Name, parameters[5]);
        Console::WriteLine("[Bridge]   Param[6] type: {0}, value: {1}", parameters[6]->GetType()->Name, parameters[6]);
        
        // Invoke
        Console::WriteLine("[Bridge] Calling OliveMatrixLibCore.Processing.RunAnalysis...");
        Object^ result = method->Invoke(instance, parameters);
        
        // Extract out parameters
        *fCov = Convert::ToDouble(parameters[3]);
        *meanNdvi = Convert::ToDouble(parameters[4]);
        
        int returnCode = safe_cast<int>(result);
        
        if (returnCode == 0)
        {
            Console::WriteLine("[Bridge] Analysis SUCCESSFUL. Result: {0}, fCov: {1}, meanNdvi: {2}", 
                returnCode, *fCov, *meanNdvi);
        }
        else
        {
            Console::WriteLine("[Bridge] Analysis FAILED. Error code: {0}", returnCode);
            Console::WriteLine("[Bridge]   fCov: {0}", *fCov);
            Console::WriteLine("[Bridge]   meanNdvi: {0}", *meanNdvi);
        }
        
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
