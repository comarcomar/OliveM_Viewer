using System;
using System.Runtime.InteropServices;
using System.Reflection;
using System.IO;

namespace OliveMatrixWrapper
{
    // Delegate matching the C++ function pointer signature
    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    public delegate int RunAnalysisDelegate(
        IntPtr srcDsmDatasetPtr,
        IntPtr srcNdviDatasetPtr,
        IntPtr shapefileZipPtr,
        IntPtr fCovPtr,
        IntPtr meanNdviPtr,
        bool denoiseFlag,
        int areaThreshold
    );

    public static class NativeInterop
    {
        private static Assembly? _oliveMatrixAssembly = null;
        private static Type? _coreType = null;
        
        // Keep delegate alive to prevent GC
        private static RunAnalysisDelegate? _delegateInstance = null;
        
        /// <summary>
        /// Get function pointer for RunAnalysis
        /// This is called from C++ via GetProcAddress-style lookup
        /// </summary>
        public static IntPtr GetRunAnalysisFunctionPointer()
        {
            if (_delegateInstance == null)
            {
                _delegateInstance = new RunAnalysisDelegate(RunAnalysis);
            }
            return Marshal.GetFunctionPointerForDelegate(_delegateInstance);
        }
        
        /// <summary>
        /// Actual implementation
        /// </summary>
        private static int RunAnalysis(
            IntPtr srcDsmDatasetPtr,
            IntPtr srcNdviDatasetPtr,
            IntPtr shapefileZipPtr,
            IntPtr fCovPtr,
            IntPtr meanNdviPtr,
            bool denoiseFlag,
            int areaThreshold)
        {
            try
            {
                // Convert UTF-8 pointers to C# strings
                string srcDsmDataset = Marshal.PtrToStringUTF8(srcDsmDatasetPtr) ?? string.Empty;
                string srcNdviDataset = Marshal.PtrToStringUTF8(srcNdviDatasetPtr) ?? string.Empty;
                string shapefileZip = Marshal.PtrToStringUTF8(shapefileZipPtr) ?? string.Empty;
                
                Console.WriteLine("[Wrapper] RunAnalysis called");
                Console.WriteLine($"[Wrapper]   DSM: {srcDsmDataset}");
                Console.WriteLine($"[Wrapper]   NDVI: {srcNdviDataset}");
                Console.WriteLine($"[Wrapper]   Shapefile: {shapefileZip}");
                Console.WriteLine($"[Wrapper]   Denoise: {denoiseFlag}");
                Console.WriteLine($"[Wrapper]   AreaThreshold: {areaThreshold}");
                
                // Load OliveMatrixLibCore
                if (!EnsureAssemblyLoaded())
                {
                    Console.WriteLine("[Wrapper] Failed to load OliveMatrixLibCore");
                    Marshal.WriteInt64(fCovPtr, 0);
                    Marshal.WriteInt64(meanNdviPtr, 0);
                    return -1;
                }
                
                // Create instance
                var instance = Activator.CreateInstance(_coreType!);
                if (instance == null)
                {
                    Console.WriteLine("[Wrapper] Failed to create instance");
                    Marshal.WriteInt64(fCovPtr, 0);
                    Marshal.WriteInt64(meanNdviPtr, 0);
                    return -1;
                }
                
                // Find RunAnalysis method
                var method = _coreType!.GetMethod("RunAnalysis");
                if (method == null)
                {
                    Console.WriteLine("[Wrapper] RunAnalysis method not found");
                    Marshal.WriteInt64(fCovPtr, 0);
                    Marshal.WriteInt64(meanNdviPtr, 0);
                    return -1;
                }
                
                // Prepare parameters
                object[] parameters = new object[]
                {
                    srcDsmDataset,
                    srcNdviDataset,
                    shapefileZip,
                    0.0,  // out fCov
                    0.0,  // out meanNdvi
                    denoiseFlag,
                    areaThreshold
                };
                
                // Invoke method
                Console.WriteLine("[Wrapper] Calling OliveMatrixLibCore.RunAnalysis...");
                var result = method.Invoke(instance, parameters);
                
                // Extract out parameters
                double fCov = Convert.ToDouble(parameters[3]);
                double meanNdvi = Convert.ToDouble(parameters[4]);
                
                // Write back to pointers using Marshal
                Marshal.WriteInt64(fCovPtr, BitConverter.DoubleToInt64Bits(fCov));
                Marshal.WriteInt64(meanNdviPtr, BitConverter.DoubleToInt64Bits(meanNdvi));
                
                int returnCode = result is int intResult ? intResult : 0;
                
                Console.WriteLine($"[Wrapper] Analysis complete. Result: {returnCode}, fCov: {fCov}, meanNdvi: {meanNdvi}");
                
                return returnCode;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Wrapper] EXCEPTION: {ex.Message}");
                Console.WriteLine($"[Wrapper] Stack trace: {ex.StackTrace}");
                
                if (ex.InnerException != null)
                {
                    Console.WriteLine($"[Wrapper] Inner exception: {ex.InnerException.Message}");
                }
                
                Marshal.WriteInt64(fCovPtr, 0);
                Marshal.WriteInt64(meanNdviPtr, 0);
                return -1;
            }
        }
        
        private static bool EnsureAssemblyLoaded()
        {
            if (_oliveMatrixAssembly != null && _coreType != null)
                return true;
            
            try
            {
                string currentDir = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location) ?? "";
                string dllPath = Path.Combine(currentDir, "OliveMatrixLibCore.dll");
                
                Console.WriteLine($"[Wrapper] Loading OliveMatrixLibCore from: {dllPath}");
                
                if (!File.Exists(dllPath))
                {
                    Console.WriteLine($"[Wrapper] ERROR: OliveMatrixLibCore.dll not found");
                    return false;
                }
                
                _oliveMatrixAssembly = Assembly.LoadFrom(dllPath);
                _coreType = _oliveMatrixAssembly.GetType("OliveMatrixLib.OliveMatrixLibCore");
                
                if (_coreType == null)
                {
                    Console.WriteLine("[Wrapper] ERROR: Type 'OliveMatrixLib.OliveMatrixLibCore' not found");
                    return false;
                }
                
                Console.WriteLine("[Wrapper] Successfully loaded OliveMatrixLibCore assembly");
                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Wrapper] ERROR loading assembly: {ex.Message}");
                return false;
            }
        }
    }
}
