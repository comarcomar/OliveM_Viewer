/**
 * OliveMatrixLib.cpp
 * 
 * Example implementation of the Olive Matrix Analysis Library
 * This is a reference implementation showing how the DLL should be structured
 */

#include "OliveMatrixLib.h"
#include <cstring>
#include <cstdio>
#include <cmath>

// For GDAL processing
#ifdef USE_GDAL
#include <gdal_priv.h>
#include <cpl_conv.h>
#endif

/**
 * Example implementation of RunAnalysis
 * 
 * This is a simplified example. A real implementation would:
 * 1. Load both GeoTIFF images using GDAL
 * 2. Perform matrix operations (correlation, NDVI, change detection, etc.)
 * 3. Generate an output GeoTIFF with results
 * 4. Calculate meaningful parameters from the analysis
 */
OLIVEMATRIX_API bool RunAnalysis(
    const char* image1Path,
    const char* image2Path,
    char* outputPath,
    double* param1,
    double* param2)
{
    // Validate inputs
    if (!image1Path || !image2Path || !outputPath || !param1 || !param2) {
        return false;
    }

#ifdef USE_GDAL
    // Initialize GDAL
    GDALAllRegister();

    // Open first image
    GDALDataset* ds1 = (GDALDataset*)GDALOpen(image1Path, GA_ReadOnly);
    if (!ds1) {
        return false;
    }

    // Open second image
    GDALDataset* ds2 = (GDALDataset*)GDALOpen(image2Path, GA_ReadOnly);
    if (!ds2) {
        GDALClose(ds1);
        return false;
    }

    // Verify dimensions match
    int width1 = ds1->GetRasterXSize();
    int height1 = ds1->GetRasterYSize();
    int width2 = ds2->GetRasterXSize();
    int height2 = ds2->GetRasterYSize();

    if (width1 != width2 || height1 != height2) {
        GDALClose(ds1);
        GDALClose(ds2);
        return false;
    }

    // Get first band from each
    GDALRasterBand* band1 = ds1->GetRasterBand(1);
    GDALRasterBand* band2 = ds2->GetRasterBand(1);

    // Read data
    float* data1 = new float[width1 * height1];
    float* data2 = new float[width1 * height1];
    float* result = new float[width1 * height1];

    band1->RasterIO(GF_Read, 0, 0, width1, height1, data1, width1, height1, GDT_Float32, 0, 0);
    band2->RasterIO(GF_Read, 0, 0, width1, height1, data2, width1, height1, GDT_Float32, 0, 0);

    // Perform analysis - Example: Normalized Difference
    double sumDiff = 0.0;
    double sumRatio = 0.0;
    int validPixels = 0;

    for (int i = 0; i < width1 * height1; ++i) {
        float v1 = data1[i];
        float v2 = data2[i];
        
        // Calculate normalized difference
        float sum = v1 + v2;
        if (fabs(sum) > 1e-6) {
            result[i] = (v1 - v2) / sum;
            sumDiff += fabs(v1 - v2);
            sumRatio += result[i];
            validPixels++;
        } else {
            result[i] = 0.0;
        }
    }

    // Calculate parameters
    *param1 = validPixels > 0 ? sumDiff / validPixels : 0.0;
    *param2 = validPixels > 0 ? sumRatio / validPixels : 0.0;

    // Create output GeoTIFF
    sprintf(outputPath, "%s/olive_analysis_result.tif", getenv("TEMP") ? getenv("TEMP") : "/tmp");

    GDALDriver* driver = GetGDALDriverManager()->GetDriverByName("GTiff");
    GDALDataset* dsOut = driver->Create(outputPath, width1, height1, 1, GDT_Float32, NULL);

    if (dsOut) {
        // Copy geotransform and projection from input
        double geoTransform[6];
        ds1->GetGeoTransform(geoTransform);
        dsOut->SetGeoTransform(geoTransform);
        dsOut->SetProjection(ds1->GetProjectionRef());

        // Write result
        GDALRasterBand* outBand = dsOut->GetRasterBand(1);
        outBand->RasterIO(GF_Write, 0, 0, width1, height1, result, width1, height1, GDT_Float32, 0, 0);

        GDALClose(dsOut);
    }

    // Cleanup
    delete[] data1;
    delete[] data2;
    delete[] result;
    GDALClose(ds1);
    GDALClose(ds2);

    return true;
#else
    // Simplified version without GDAL
    // Just create a dummy output path and generate example parameters
    
    sprintf(outputPath, "%s/olive_analysis_result.tif", 
            getenv("TEMP") ? getenv("TEMP") : "/tmp");
    
    // Generate example parameters based on file names
    *param1 = 42.5678 + (strlen(image1Path) % 10);
    *param2 = 87.1234 + (strlen(image2Path) % 10);
    
    return true;
#endif
}
