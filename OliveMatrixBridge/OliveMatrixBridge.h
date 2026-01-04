#pragma once

#ifdef OLIVEMATRIXBRIDGE_EXPORTS
#define OLIVEMATRIX_API __declspec(dllexport)
#else
#define OLIVEMATRIX_API __declspec(dllimport)
#endif

extern "C" {
    // Native C-style export for use from Qt C++
    OLIVEMATRIX_API int RunOliveMatrixAnalysis(
        const char* srcDsmDataset,
        const char* srcNdviDataset,
        const char* shapefileZip,
        double* fCov,
        double* meanNdvi,
        bool denoiseFlag,
        int areaThreshold
    );
}
