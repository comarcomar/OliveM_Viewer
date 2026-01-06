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
        
        // Get bridge directory (where OliveMatrixBridge.dll is)
        String^ bridgeDir = Path::GetDirectoryName(Assembly::GetExecutingAssembly()->Location);
        
        // OliveMatrixLibCore is in "olivematrix" subdirectory
        String^ omDir = Path::Combine(bridgeDir, "olivematrix");
        String^ coreLibPath = Path::Combine(omDir, "OliveMatrixLibCore.dll");
        
        Console::WriteLine("[Bridge] Bridge directory: {0}", bridgeDir);
        Console::WriteLine("[Bridge] OliveMatrix directory: {0}", omDir);
        Console::WriteLine("[Bridge] Looking for: {0}", coreLibPath);
        
        if (!Directory::Exists(omDir))
        {
            Console::WriteLine("[Bridge] ERROR: olivematrix subdirectory not found");
            *fCov = 0.0;
            *meanNdvi = 0.0;
            return -1;
        }
        
        if (!File::Exists(coreLibPath))
        {
            Console::WriteLine("[Bridge] ERROR: OliveMatrixLibCore.dll not found");
            *fCov = 0.0;
            *meanNdvi = 0.0;
            return -1;
        }
        
        // CRITICAL: Change to olivematrix subdirectory
        // This forces .NET to load all DLLs from there (gdal313.dll, geos, etc)
        String^ originalDir = Directory::GetCurrentDirectory();
        Console::WriteLine("[Bridge] Original directory: {0}", originalDir);
        Console::WriteLine("[Bridge] Changing to: {0}", omDir);
        Directory::SetCurrentDirectory(omDir);
        
        try
        {
            // Load assembly
            Console::WriteLine("[Bridge] Loading OliveMatrixLibCore assembly...");
            Assembly^ coreAssembly = Assembly::LoadFrom(coreLibPath);
            
            // Get Processing type
            Type^ coreType = coreAssembly->GetType("OliveMatrixLibCore.Processing");
            
            if (coreType == nullptr)
            {
                Console::WriteLine("[Bridge] ERROR: Type OliveMatrixLibCore.Processing not found");
                Directory::SetCurrentDirectory(originalDir);
                *fCov = 0.0;
                *meanNdvi = 0.0;
                return -1;
            }
            
            Console::WriteLine("[Bridge] Found type: OliveMatrixLibCore.Processing");
            
            // Create instance
            Console::WriteLine("[Bridge] Creating Processing instance...");
            Object^ instance = Activator::CreateInstance(coreType);
            
            if (instance == nullptr)
            {
                Console::WriteLine("[Bridge] ERROR: Failed to create Processing instance");
                Directory::SetCurrentDirectory(originalDir);
                *fCov = 0.0;
                *meanNdvi = 0.0;
                return -1;
            }
            
            // Get RunAnalysis method
            MethodInfo^ method = coreType->GetMethod("RunAnalysis");
            if (method == nullptr)
            {
                Console::WriteLine("[Bridge] ERROR: RunAnalysis method not found in Processing");
                Directory::SetCurrentDirectory(originalDir);
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
            
            // Invoke
            Console::WriteLine("[Bridge] Calling OliveMatrixLibCore.Processing.RunAnalysis...");
            Object^ result = method->Invoke(instance, parameters);
            
            // Extract out parameters
            *fCov = Convert::ToDouble(parameters[3]);
            *meanNdvi = Convert::ToDouble(parameters[4]);
            
            int returnCode = safe_cast<int>(result);
            
            Console::WriteLine("[Bridge] Analysis complete. Result: {0}, fCov: {1}, meanNdvi: {2}", 
                returnCode, *fCov, *meanNdvi);
            
            // Restore original directory
            Directory::SetCurrentDirectory(originalDir);
            Console::WriteLine("[Bridge] Restored directory to: {0}", originalDir);
            
            return returnCode;
        }
        catch (Exception^ ex)
        {
            // Restore directory even on error
            Directory::SetCurrentDirectory(originalDir);
            throw;
        }
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
