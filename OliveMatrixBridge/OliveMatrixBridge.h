#pragma once

#ifdef OLIVEMATRIXBRIDGE_EXPORTS
#define OLIVEMATRIX_API __declspec(dllexport)
#else
#define OLIVEMATRIX_API __declspec(dllimport)
#endif

extern "C" {
    // Native C-style export for use from Qt C++
    // Use wchar_t* for proper UTF-16 marshaling to C# String
    OLIVEMATRIX_API int RunOliveMatrixAnalysis(
        const wchar_t* srcDsmDataset,
        const wchar_t* srcNdviDataset,
        const wchar_t* shapefileZip,
        double* fCov,
        double* meanNdvi,
        bool denoiseFlag,
        int areaThreshold
    );
}
