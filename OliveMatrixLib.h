/**
 * OliveMatrixLib.h
 * 
 * Header file for the Olive Matrix Analysis Library
 * This defines the interface for the RunAnalysis function
 * that will be called by the GeoTIFF viewer application
 */

#ifndef OLIVEMATRIXLIB_H
#define OLIVEMATRIXLIB_H

#ifdef _WIN32
    #ifdef OLIVEMATRIXLIB_EXPORTS
        #define OLIVEMATRIX_API __declspec(dllexport)
    #else
        #define OLIVEMATRIX_API __declspec(dllimport)
    #endif
#else
    #define OLIVEMATRIX_API
#endif

#ifdef __cplusplus
extern "C" {
#endif

/**
 * RunAnalysis - Main analysis function
 * 
 * Performs matrix analysis on two GeoTIFF images and produces a result image
 * along with two computed parameters.
 * 
 * @param image1Path - Full path to the first GeoTIFF image
 * @param image2Path - Full path to the second GeoTIFF image
 * @param outputPath - Buffer to receive the output image path (min 1024 bytes)
 * @param param1 - Pointer to receive the first computed parameter
 * @param param2 - Pointer to receive the second computed parameter
 * 
 * @return true if analysis completed successfully, false otherwise
 */
OLIVEMATRIX_API bool RunAnalysis(
    const char* image1Path,
    const char* image2Path,
    char* outputPath,
    double* param1,
    double* param2
);

#ifdef __cplusplus
}
#endif

#endif // OLIVEMATRIXLIB_H
