#include "geotiffprocessor.h"
#include <QDebug>
#include <QFileInfo>
#include <QDir>
#include <QUrl>
#include <QCoreApplication>
#include <QLibrary>
#include <QFile>
#include <string>
#include <cmath>
#include <gdal_priv.h>
#include <cpl_conv.h>

GeoTiffProcessor::GeoTiffProcessor(QObject *parent)
    : QObject(parent)
    , m_hasImage1(false)
    , m_hasImage2(false)
    , m_denoiseFlag(false)
    , m_areaThreshold(70)
{
    // Initialize GDAL
    GDALAllRegister();
}

GeoTiffProcessor::~GeoTiffProcessor()
{
}

bool GeoTiffProcessor::hasValidImages() const
{
    return m_hasImage1 && m_hasImage2;
}

void GeoTiffProcessor::setImage1(const QString &path)
{
    m_image1Path = path;
    m_hasImage1 = loadGeoTiff(path);
    emit imagesChanged();
    
    if (!m_hasImage1) {
        emit errorOccurred("Failed to load Image 1: " + path);
    }
}

void GeoTiffProcessor::setImage2(const QString &path)
{
    m_image2Path = path;
    m_hasImage2 = loadGeoTiff(path);
    emit imagesChanged();
    
    if (!m_hasImage2) {
        emit errorOccurred("Failed to load Image 2: " + path);
    }
}

void GeoTiffProcessor::setShapefileZip(const QString &path)
{
    m_shapefileZipPath = path;
    qDebug() << "Shapefile ZIP set:" << path;
}

void GeoTiffProcessor::setDenoiseFlag(bool enabled)
{
    m_denoiseFlag = enabled;
    qDebug() << "Denoise flag set to:" << enabled;
}

void GeoTiffProcessor::setAreaThreshold(int threshold)
{
    m_areaThreshold = threshold;
    qDebug() << "Area threshold set to:" << threshold;
}

bool GeoTiffProcessor::loadGeoTiff(const QString &path)
{
    QFileInfo fileInfo(path);
    if (!fileInfo.exists()) {
        qWarning() << "File does not exist:" << path;
        return false;
    }

    // Open with GDAL
    GDALDataset *dataset = (GDALDataset*)GDALOpen(path.toUtf8().constData(), GA_ReadOnly);
    if (dataset == nullptr) {
        qWarning() << "Failed to open GeoTIFF:" << path;
        return false;
    }

    // Validate it's a proper GeoTIFF
    int rasterCount = dataset->GetRasterCount();
    if (rasterCount == 0) {
        qWarning() << "No raster bands found in:" << path;
        GDALClose(dataset);
        return false;
    }

    qDebug() << "Successfully loaded GeoTIFF:" << path;
    qDebug() << "Dimensions:" << dataset->GetRasterXSize() << "x" << dataset->GetRasterYSize();
    qDebug() << "Bands:" << rasterCount;

    GDALClose(dataset);
    return true;
}

void GeoTiffProcessor::runAnalysis()
{
    if (!hasValidImages()) {
        emit errorOccurred("Both DSM and NDVI images must be loaded before running analysis");
        return;
    }

    QString outputPath;
    double fCov = 0.0;
    double meanNdvi = 0.0;

    if (callRunAnalysis(m_image1Path, m_image2Path, m_shapefileZipPath, outputPath, fCov, meanNdvi)) {
        emit analysisCompleted(outputPath, fCov, meanNdvi);
    } else {
        emit errorOccurred("Analysis failed. Check that OliveMatrixBridge.dll and OliveMatrixLibCore.dll are available and .NET 6 runtime is installed.");
    }
}

bool GeoTiffProcessor::callRunAnalysis(const QString &dsmPath, const QString &ndviPath,
                                        const QString &shapefileZip, QString &outputPath, 
                                        double &fCov, double &meanNdvi)
{
    qDebug() << "=== Loading OliveMatrixBridge (C++/CLI) ===";
    
    QString appDir = QCoreApplication::applicationDirPath();
    QString bridgeDll = appDir + "/OliveMatrixBridge.dll";
    
    qDebug() << "Application directory:" << appDir;
    qDebug() << "Bridge DLL:" << bridgeDll;
    
    // Check if bridge exists
    if (!QFile::exists(bridgeDll))
    {
        qWarning() << "OliveMatrixBridge.dll not found at:" << bridgeDll;
        qWarning() << "Make sure OliveMatrixBridge was built in Visual Studio";
        return false;
    }
    
    qDebug() << "OliveMatrixBridge.dll exists, checking dependencies...";
    
    // Check if OliveMatrixLibCore.dll exists in same directory
    QString coreLib = appDir + "/OliveMatrixLibCore.dll";
    if (!QFile::exists(coreLib))
    {
        qWarning() << "OliveMatrixLibCore.dll not found at:" << coreLib;
        qWarning() << "Run CMake and build to deploy OliveMatrixLibCore";
        return false;
    }
    
    qDebug() << "OliveMatrixLibCore.dll found in app directory";
    
    // Load bridge DLL
    QLibrary bridge(bridgeDll);
    
    if (!bridge.load())
    {
        qWarning() << "Failed to load OliveMatrixBridge.dll:" << bridge.errorString();
        qWarning() << "";
        qWarning() << "Possible causes:";
        qWarning() << "1. .NET 6 Desktop Runtime not installed";
        qWarning() << "   Download from: https://dotnet.microsoft.com/download/dotnet/6.0";
        qWarning() << "2. Visual C++ Redistributable missing";
        qWarning() << "   Download from: https://aka.ms/vs/17/release/vc_redist.x64.exe";
        qWarning() << "3. Bridge built for wrong platform (must be x64)";
        qWarning() << "";

        return false;
    }
    
    qDebug() << "Successfully loaded OliveMatrixBridge.dll";
    
    // Get function pointer
    typedef int (*RunAnalysisFunc)(const wchar_t*, const wchar_t*, const wchar_t*, 
                                    double*, double*, bool, int);
    
    RunAnalysisFunc runAnalysis = (RunAnalysisFunc)bridge.resolve("RunOliveMatrixAnalysis");
    
    if (!runAnalysis)
    {
        qWarning() << "Failed to resolve RunOliveMatrixAnalysis function";
        bridge.unload();
        return false;
    }
    
    qDebug() << "Successfully resolved RunOliveMatrixAnalysis function";
    
    // Convert to Windows native format (backslashes)
    // OliveMatrixLibCore uses Windows paths internally
    QString winDsmPath = QDir::toNativeSeparators(dsmPath);
    QString winNdviPath = QDir::toNativeSeparators(ndviPath);
    QString winShapefilePath = shapefileZip.isEmpty() ? QString() : QDir::toNativeSeparators(shapefileZip);
    
    // Manual conversion QString -> wchar_t* (UTF-16)
    const ushort* dsmUtf16 = winDsmPath.utf16();
    const ushort* ndviUtf16 = winNdviPath.utf16();
    const ushort* shapeUtf16 = winShapefilePath.isEmpty() ? nullptr : winShapefilePath.utf16();
    
    // Cast ushort* to wchar_t*
    const wchar_t* dsmWide = reinterpret_cast<const wchar_t*>(dsmUtf16);
    const wchar_t* ndviWide = reinterpret_cast<const wchar_t*>(ndviUtf16);
    const wchar_t* shapeWide = shapeUtf16 ? reinterpret_cast<const wchar_t*>(shapeUtf16) : L"";
    
    qDebug() << "Calling RunOliveMatrixAnalysis with Windows paths:";
    qDebug() << "  DSM:" << winDsmPath;
    qDebug() << "  NDVI:" << winNdviPath;
    qDebug() << "  Shapefile:" << (winShapefilePath.isEmpty() ? "(none)" : winShapefilePath);
    qDebug() << "  Denoise:" << m_denoiseFlag;
    qDebug() << "  AreaThreshold:" << m_areaThreshold;
    
    // OliveMatrixLibCore creates clippedDir automatically
    
    // Call with direct wchar_t* from QString::utf16()
    int result = runAnalysis(
        dsmWide,
        ndviWide,
        shapeWide,
        &fCov,
        &meanNdvi,
        m_denoiseFlag,
        m_areaThreshold
    );
    
    bridge.unload();
    
    qDebug() << "Analysis completed with result code:" << result;
    
    if (result == 0)
    {
        // Success - OliveMatrixLibCore saves output in clippedDir subdirectory
        // File format: treeCrown_<timestamp>.tif
        
        qDebug() << "Analysis successful";
        qDebug() << "  fCov:" << fCov;
        qDebug() << "  meanNdvi:" << meanNdvi;
        
        // Find output file in clippedDir subdirectory of DSM directory
        QFileInfo dsmInfo(dsmPath);
        QString dsmDir = dsmInfo.absolutePath();
        QString clippedDir = dsmDir + "/clippedDir";  // Forward slash
        
        qDebug() << "  DSM directory:" << dsmDir;
        qDebug() << "  Looking for output in:" << clippedDir;
        
        if (!QDir(clippedDir).exists())
        {
            qWarning() << "clippedDir subdirectory not found at:" << clippedDir;
            qWarning() << "OliveMatrixLibCore may not have created output files";
            return false;
        }
        
        // Find treeCrown_*.tif file (newest one)
        QDir outputDir(clippedDir);
        QStringList filters;
        filters << "treeCrown_*.tif";
        QFileInfoList files = outputDir.entryInfoList(filters, QDir::Files, QDir::Time);
        
        if (files.isEmpty())
        {
            qWarning() << "No treeCrown_*.tif file found in:" << clippedDir;
            qWarning() << "Available files:";
            QFileInfoList allFiles = outputDir.entryInfoList(QDir::Files);
            for (const QFileInfo &file : allFiles)
            {
                qWarning() << "  -" << file.fileName();
            }
            return false;
        }
        
        // Get most recent file (first in time-sorted list)
        outputPath = files.first().absoluteFilePath();
        qDebug() << "  Output file:" << outputPath;
        
        return true;
    }
    else
    {
        qWarning() << "Analysis FAILED with error code:" << result;
        qWarning() << "";
        qWarning() << "Error code meanings:";
        qWarning() << "  -1  : General error";
        qWarning() << "  -37 : File not found or GDAL error";
        qWarning() << "  Other: Check OliveMatrixLibCore documentation";
        qWarning() << "";
        qWarning() << "Check console output above for detailed error messages from [Bridge]";
        return false;
    }
}

// Statistics methods

// ============================================================================
// GeoTiffImageProvider Implementation
// ============================================================================

GeoTiffImageProvider::GeoTiffImageProvider()
    : QQuickImageProvider(QQuickImageProvider::Image)
{
}

QImage GeoTiffImageProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize)
{
    qDebug() << "GeoTiffImageProvider::requestImage called with id:" << id;
    
    // Parse the id: "encoded_path?colormap=0&t=timestamp"
    QStringList parts = id.split("?");
    if (parts.isEmpty()) {
        qWarning() << "Invalid image ID format";
        return QImage();
    }
    
    // Decode the file path
    QString filePath = QUrl::fromPercentEncoding(parts[0].toUtf8());
    qDebug() << "Decoded file path:" << filePath;
    
    // Parse parameters
    int colorMapIndex = 0;
    if (parts.size() > 1) {
        QStringList params = parts[1].split("&");
        for (const QString &param : params) {
            if (param.startsWith("colormap=")) {
                colorMapIndex = param.mid(9).toInt();
            }
        }
    }
    
    qDebug() << "Using colormap index:" << colorMapIndex;
    
    // Verify file exists
    QFileInfo fileInfo(filePath);
    if (!fileInfo.exists()) {
        qWarning() << "File does not exist:" << filePath;
        qWarning() << "Absolute path:" << fileInfo.absoluteFilePath();
        return QImage();
    }
    
    qDebug() << "Opening GeoTIFF:" << fileInfo.absoluteFilePath();

    // Open the GeoTIFF with GDAL
    GDALDataset *dataset = (GDALDataset*)GDALOpen(fileInfo.absoluteFilePath().toUtf8().constData(), GA_ReadOnly);
    if (dataset == nullptr) {
        qWarning() << "Failed to open GeoTIFF with GDAL:" << filePath;
        qWarning() << "GDAL Error:" << CPLGetLastErrorMsg();
        return QImage();
    }

    qDebug() << "GDAL dataset opened successfully";
    qDebug() << "Raster size:" << dataset->GetRasterXSize() << "x" << dataset->GetRasterYSize();
    qDebug() << "Number of bands:" << dataset->GetRasterCount();

    int numBands = dataset->GetRasterCount();
    
    // Check if this is RGB (colormap=-1 means RGB passthrough)
    bool isRGB = (colorMapIndex == -1 && numBands >= 3);
    
    if (isRGB) {
        qDebug() << "Processing as RGB image (3 bands)";
        
        // Get dimensions from first band
        GDALRasterBand *band1 = dataset->GetRasterBand(1);
        int width = band1->GetXSize();
        int height = band1->GetYSize();
        
        // Downsample for memory
        int maxDim = 2048;
        double scale = 1.0;
        if (width > maxDim || height > maxDim) {
            scale = std::min((double)maxDim / width, (double)maxDim / height);
        }
        int outWidth = (int)(width * scale);
        int outHeight = (int)(height * scale);
        
        qDebug() << "Downsampling from" << width << "x" << height << "to" << outWidth << "x" << outHeight;
        
        // Read RGB bands
        std::vector<float> dataR(outWidth * outHeight);
        std::vector<float> dataG(outWidth * outHeight);
        std::vector<float> dataB(outWidth * outHeight);
        
        GDALRasterBand *bandR = dataset->GetRasterBand(1);
        GDALRasterBand *bandG = dataset->GetRasterBand(2);
        GDALRasterBand *bandB = dataset->GetRasterBand(3);
        
        bandR->RasterIO(GF_Read, 0, 0, width, height, dataR.data(), outWidth, outHeight, GDT_Float32, 0, 0);
        bandG->RasterIO(GF_Read, 0, 0, width, height, dataG.data(), outWidth, outHeight, GDT_Float32, 0, 0);
        bandB->RasterIO(GF_Read, 0, 0, width, height, dataB.data(), outWidth, outHeight, GDT_Float32, 0, 0);
        
        // Find min/max for normalization
        float minR = *std::min_element(dataR.begin(), dataR.end());
        float maxR = *std::max_element(dataR.begin(), dataR.end());
        float minG = *std::min_element(dataG.begin(), dataG.end());
        float maxG = *std::max_element(dataG.begin(), dataG.end());
        float minB = *std::min_element(dataB.begin(), dataB.end());
        float maxB = *std::max_element(dataB.begin(), dataB.end());
        
        qDebug() << "RGB ranges - R:" << minR << "-" << maxR << "G:" << minG << "-" << maxG << "B:" << minB << "-" << maxB;
        
        // Create QImage
        QImage image(outWidth, outHeight, QImage::Format_RGB888);
        
        for (int y = 0; y < outHeight; y++) {
            for (int x = 0; x < outWidth; x++) {
                int idx = y * outWidth + x;
                int r = (int)((dataR[idx] - minR) / (maxR - minR) * 255);
                int g = (int)((dataG[idx] - minG) / (maxG - minG) * 255);
                int b = (int)((dataB[idx] - minB) / (maxB - minB) * 255);
                r = std::max(0, std::min(255, r));
                g = std::max(0, std::min(255, g));
                b = std::max(0, std::min(255, b));
                image.setPixel(x, y, qRgb(r, g, b));
            }
        }
        
        GDALClose(dataset);
        
        if (size) *size = image.size();
        qDebug() << "RGB image generation complete:" << image.size();
        return image;
    }

    // Single band processing (original code)
    // Get the first band
    GDALRasterBand *band = dataset->GetRasterBand(1);
    if (band == nullptr) {
        qWarning() << "No raster band found";
        GDALClose(dataset);
        return QImage();
    }

    int width = band->GetXSize();
    int height = band->GetYSize();
    GDALDataType dataType = band->GetRasterDataType();
    
    qDebug() << "Band info - Width:" << width << "Height:" << height << "Type:" << dataType;

    // Determine output size (downsample if requested)
    int outWidth = width;
    int outHeight = height;
    
    if (requestedSize.width() > 0 && requestedSize.height() > 0) {
        // Calculate aspect-preserving size
        double aspectRatio = (double)width / height;
        outWidth = requestedSize.width();
        outHeight = (int)(outWidth / aspectRatio);
        
        if (outHeight > requestedSize.height()) {
            outHeight = requestedSize.height();
            outWidth = (int)(outHeight * aspectRatio);
        }
        
        qDebug() << "Downsampling to:" << outWidth << "x" << outHeight;
    }

    // Allocate buffer for reading data
    float *buffer = new float[outWidth * outHeight];
    
    // Read the data with resampling
    CPLErr err = band->RasterIO(
        GF_Read,
        0, 0,                    // Source offset
        width, height,           // Source size
        buffer,                  // Buffer
        outWidth, outHeight,     // Buffer size
        GDT_Float32,            // Buffer type
        0, 0                    // Pixel/line spacing
    );

    if (err != CE_None) {
        qWarning() << "Failed to read raster data:" << CPLGetLastErrorMsg();
        delete[] buffer;
        GDALClose(dataset);
        return QImage();
    }
    
    qDebug() << "Raster data read successfully";

    // Get statistics for normalization
    double minVal, maxVal, meanVal, stdDev;
    band->ComputeStatistics(false, &minVal, &maxVal, &meanVal, &stdDev, nullptr, nullptr);
    
    qDebug() << "Statistics - Min:" << minVal << "Max:" << maxVal << "Mean:" << meanVal << "StdDev:" << stdDev;
    
    // Handle invalid statistics
    if (minVal == maxVal || std::isnan(minVal) || std::isnan(maxVal)) {
        qWarning() << "Invalid statistics, computing from buffer";
        minVal = buffer[0];
        maxVal = buffer[0];
        for (int i = 1; i < outWidth * outHeight; ++i) {
            if (!std::isnan(buffer[i]) && !std::isinf(buffer[i])) {
                if (buffer[i] < minVal) minVal = buffer[i];
                if (buffer[i] > maxVal) maxVal = buffer[i];
            }
        }
    }

    // Create output image
    QImage image(outWidth, outHeight, QImage::Format_RGB32);
    
    double range = maxVal - minVal;
    if (range < 1e-10) range = 1.0; // Avoid division by zero
    
    // Fill image with color-mapped values
    QVector<QColor> colors = getColorMapColors(colorMapIndex);
    
    for (int y = 0; y < outHeight; ++y) {
        QRgb *scanLine = (QRgb*)image.scanLine(y);
        for (int x = 0; x < outWidth; ++x) {
            float value = buffer[y * outWidth + x];
            
            // Handle NaN and Inf
            if (std::isnan(value) || std::isinf(value)) {
                scanLine[x] = qRgb(0, 0, 0); // Black for invalid values
                continue;
            }
            
            // Normalize to 0-1
            double normalized = (value - minVal) / range;
            normalized = qBound(0.0, normalized, 1.0);
            
            // Map to color
            int colorIndex = (int)(normalized * (colors.size() - 1));
            colorIndex = qBound(0, colorIndex, colors.size() - 2);
            
            double localPos = normalized * (colors.size() - 1) - colorIndex;
            
            QColor c1 = colors[colorIndex];
            QColor c2 = colors[colorIndex + 1];
            
            int r = c1.red() + localPos * (c2.red() - c1.red());
            int g = c1.green() + localPos * (c2.green() - c1.green());
            int b = c1.blue() + localPos * (c2.blue() - c1.blue());
            
            scanLine[x] = qRgb(qBound(0, r, 255), qBound(0, g, 255), qBound(0, b, 255));
        }
    }

    delete[] buffer;
    GDALClose(dataset);
    
    if (size) {
        *size = image.size();
    }
    
    qDebug() << "Image generation complete:" << image.size();

    return image;
}

QVector<QColor> GeoTiffImageProvider::getColorMapColors(int index)
{
    switch (index) {
        case 0: // Jet
            return {QColor("#000080"), QColor("#0000FF"), QColor("#00FFFF"), 
                    QColor("#00FF00"), QColor("#FFFF00"), QColor("#FF0000"), QColor("#800000")};
        case 1: // Hot
            return {QColor("#000000"), QColor("#FF0000"), QColor("#FFFF00"), QColor("#FFFFFF")};
        case 2: // Grayscale
            return {QColor("#000000"), QColor("#FFFFFF")};
        case 3: // Viridis
            return {QColor("#440154"), QColor("#31688e"), QColor("#35b779"), QColor("#fde724")};
        default:
            return {QColor("#000000"), QColor("#FFFFFF")};
    }
}

QVariantMap GeoTiffProcessor::getImageStatistics(const QString &imagePath)
{
    QVariantMap stats;
    
    if (imagePath.isEmpty()) {
        return stats;
    }
    
    GDALDataset *dataset = (GDALDataset*)GDALOpen(imagePath.toUtf8().constData(), GA_ReadOnly);
    if (dataset == nullptr) {
        qWarning() << "Failed to open GeoTIFF for statistics:" << imagePath;
        return stats;
    }
    
    GDALRasterBand *band = dataset->GetRasterBand(1);
    if (band == nullptr) {
        qWarning() << "No raster band found for statistics";
        GDALClose(dataset);
        return stats;
    }
    
    double minVal, maxVal, meanVal, stdDev;
    CPLErr err = band->ComputeStatistics(false, &minVal, &maxVal, &meanVal, &stdDev, nullptr, nullptr);
    
    if (err == CE_None) {
        stats["min"] = minVal;
        stats["max"] = maxVal;
        stats["mean"] = meanVal;
        stats["stdDev"] = stdDev;
        stats["valid"] = true;
        
        qDebug() << "Image statistics:" << imagePath;
        qDebug() << "  Min:" << minVal << "Max:" << maxVal << "Mean:" << meanVal;
    } else {
        qWarning() << "Failed to compute statistics";
        stats["valid"] = false;
    }
    
    GDALClose(dataset);
    return stats;
}

QVariantList GeoTiffProcessor::getHeightData(const QString &imagePath, int maxWidth, int maxHeight)
{
    QVariantList result;
    
    if (imagePath.isEmpty()) {
        return result;
    }
    
    GDALDataset *dataset = (GDALDataset*)GDALOpen(imagePath.toUtf8().constData(), GA_ReadOnly);
    if (dataset == nullptr) {
        qWarning() << "Failed to open GeoTIFF for height data:" << imagePath;
        return result;
    }
    
    GDALRasterBand *band = dataset->GetRasterBand(1);
    if (band == nullptr) {
        qWarning() << "No raster band found";
        GDALClose(dataset);
        return result;
    }
    
    int width = dataset->GetRasterXSize();
    int height = dataset->GetRasterYSize();
    
    // Downsample to reasonable size
    int targetWidth = std::min(width, maxWidth);
    int targetHeight = std::min(height, maxHeight);
    
    int stepX = std::max(1, width / targetWidth);
    int stepY = std::max(1, height / targetHeight);
    
    qDebug() << "Reading height data from" << width << "x" << height 
             << "downsampled to" << (width/stepX) << "x" << (height/stepY);
    
    // Get statistics for normalization
    double minVal, maxVal, meanVal, stdDev;
    band->ComputeStatistics(false, &minVal, &maxVal, &meanVal, &stdDev, nullptr, nullptr);
    
    if (maxVal <= minVal) {
        maxVal = minVal + 1.0; // Avoid division by zero
    }
    
    // Read data
    for (int y = 0; y < height; y += stepY) {
        for (int x = 0; x < width; x += stepX) {
            float value;
            CPLErr err = band->RasterIO(GF_Read, x, y, 1, 1, &value, 1, 1, GDT_Float32, 0, 0);
            
            if (err == CE_None && !std::isnan(value) && !std::isinf(value)) {
                // Normalize to 0-1 range
                double normalized = (value - minVal) / (maxVal - minVal);
                normalized = std::max(0.0, std::min(1.0, normalized));
                
                QVariantMap point;
                point["x"] = x / stepX;
                point["y"] = y / stepY;
                point["height"] = normalized;
                point["rawValue"] = value;
                
                result.append(point);
            }
        }
    }
    
    GDALClose(dataset);
    
    qDebug() << "Generated" << result.size() << "height data points";
    return result;
}

void GeoTiffProcessor::clearCache()
{
    qDebug() << "Clearing processor cache...";
    
    // Just clear the paths, don't destroy GDAL
    m_image1Path.clear();
    m_image2Path.clear();
    m_hasImage1 = false;
    m_hasImage2 = false;
    
    emit imagesChanged();
    
    qDebug() << "Cache cleared";
}
