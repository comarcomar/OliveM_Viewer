#include "geotiffprocessor.h"
#include <QDebug>
#include <QFileInfo>
#include <QDir>
#include <QUrl>
#include <QCoreApplication>
#include <QLibrary>
#include <QFile>
#include <string>
#include <cstring>
#include <cmath>
#include <vector>
#include <gdal_priv.h>
#include <gdalwarper.h>

// Riallinea srcPath su refPath usando GDAL e restituisce QImage allineata
QImage GeoTiffProcessor::warpImageToMatch(const QString &srcPath, const QString &refPath)
{
    qDebug() << "warpImageToMatch called:";
    qDebug() << "  srcPath:" << srcPath;
    qDebug() << "  refPath:" << refPath;
    
    // Pulisci i path da file:/// e decodifica
    QString srcClean = srcPath;
    if (srcClean.startsWith("file:///")) srcClean = srcClean.mid(8);
    else if (srcClean.startsWith("file://")) srcClean = srcClean.mid(7);
    srcClean = QUrl::fromPercentEncoding(srcClean.toUtf8());
    
    QString refClean = refPath;
    if (refClean.startsWith("file:///")) refClean = refClean.mid(8);
    else if (refClean.startsWith("file://")) refClean = refClean.mid(7);
    refClean = QUrl::fromPercentEncoding(refClean.toUtf8());
    
    qDebug() << "  srcClean:" << srcClean;
    qDebug() << "  refClean:" << refClean;
    
    GDALDataset *srcDS = (GDALDataset*)GDALOpen(srcClean.toUtf8().constData(), GA_ReadOnly);
    GDALDataset *refDS = (GDALDataset*)GDALOpen(refClean.toUtf8().constData(), GA_ReadOnly);
    
    if (!srcDS || !refDS) {
        qWarning() << "Failed to open datasets for warping";
        qWarning() << "  srcDS:" << (srcDS ? "OK" : "FAILED");
        qWarning() << "  refDS:" << (refDS ? "OK" : "FAILED");
        if (srcDS) GDALClose(srcDS);
        if (refDS) GDALClose(refDS);
        return QImage();
    }

    double refGeoTransform[6];
    refDS->GetGeoTransform(refGeoTransform);
    const char *refProj = refDS->GetProjectionRef();
    const char *srcProj = srcDS->GetProjectionRef();

    qDebug() << "  refProj:" << (refProj ? refProj : "(null)");
    qDebug() << "  srcProj:" << (srcProj ? srcProj : "(null)");

    int xSize = refDS->GetRasterXSize();
    int ySize = refDS->GetRasterYSize();
    int srcBands = srcDS->GetRasterCount();
    
    qDebug() << "  refSize:" << xSize << "x" << ySize;
    qDebug() << "  srcBands:" << srcBands;
    
    // Limita la dimensione per evitare allocazioni enormi
    int maxDim = 4096;
    int outWidth = xSize;
    int outHeight = ySize;
    if (xSize > maxDim || ySize > maxDim) {
        double scale = std::min((double)maxDim / xSize, (double)maxDim / ySize);
        outWidth = static_cast<int>(xSize * scale);
        outHeight = static_cast<int>(ySize * scale);
        qDebug() << "  Downsampling output to:" << outWidth << "x" << outHeight;
    }
    
    // Se le immagini non hanno proiezione, carica senza warping
    if (!refProj || strlen(refProj) == 0 || !srcProj || strlen(srcProj) == 0) {
        qWarning() << "One or both images have no projection, loading source directly without warping";
        
        QImage img;
        if (srcBands >= 3) {
            img = QImage(outWidth, outHeight, QImage::Format_RGB32);
            std::vector<uint8_t> rBuf(outWidth * outHeight);
            std::vector<uint8_t> gBuf(outWidth * outHeight);
            std::vector<uint8_t> bBuf(outWidth * outHeight);
            srcDS->GetRasterBand(1)->RasterIO(GF_Read, 0, 0, srcDS->GetRasterXSize(), srcDS->GetRasterYSize(), rBuf.data(), outWidth, outHeight, GDT_Byte, 0, 0);
            srcDS->GetRasterBand(2)->RasterIO(GF_Read, 0, 0, srcDS->GetRasterXSize(), srcDS->GetRasterYSize(), gBuf.data(), outWidth, outHeight, GDT_Byte, 0, 0);
            srcDS->GetRasterBand(3)->RasterIO(GF_Read, 0, 0, srcDS->GetRasterXSize(), srcDS->GetRasterYSize(), bBuf.data(), outWidth, outHeight, GDT_Byte, 0, 0);
            for (int y = 0; y < outHeight; ++y) {
                QRgb *scanLine = (QRgb*)img.scanLine(y);
                for (int x = 0; x < outWidth; ++x) {
                    int idx = y * outWidth + x;
                    scanLine[x] = qRgb(rBuf[idx], gBuf[idx], bBuf[idx]);
                }
            }
        } else if (srcBands == 1) {
            img = QImage(outWidth, outHeight, QImage::Format_Grayscale8);
            srcDS->GetRasterBand(1)->RasterIO(GF_Read, 0, 0, srcDS->GetRasterXSize(), srcDS->GetRasterYSize(), img.bits(), outWidth, outHeight, GDT_Byte, 0, 0);
        }
        
        GDALClose(srcDS);
        GDALClose(refDS);
        return img;
    }
    
    GDALDriver *memDriver = GetGDALDriverManager()->GetDriverByName("MEM");
    if (!memDriver) {
        qWarning() << "Failed to get MEM driver";
        GDALClose(srcDS);
        GDALClose(refDS);
        return QImage();
    }
    
    // Usa dimensioni ridotte per l'output
    GDALDataset *outDS = memDriver->Create("", outWidth, outHeight, srcBands, GDT_Byte, nullptr);
    if (!outDS) {
        qWarning() << "Failed to create output dataset";
        GDALClose(srcDS);
        GDALClose(refDS);
        return QImage();
    }
    
    // Scala il geotransform per le nuove dimensioni
    double outGeoTransform[6];
    for (int i = 0; i < 6; i++) outGeoTransform[i] = refGeoTransform[i];
    if (outWidth != xSize || outHeight != ySize) {
        double scaleX = (double)xSize / outWidth;
        double scaleY = (double)ySize / outHeight;
        outGeoTransform[1] *= scaleX;  // pixel width
        outGeoTransform[5] *= scaleY;  // pixel height (negative)
    }
    outDS->SetGeoTransform(outGeoTransform);
    outDS->SetProjection(refProj);

    void *transformArg = GDALCreateGenImgProjTransformer(srcDS, srcProj,
                                                         outDS, refProj, FALSE, 0, 1);
    if (!transformArg) {
        qWarning() << "Failed to create projection transformer, loading source directly";
        GDALClose(outDS);
        
        // Fallback: carica l'immagine sorgente senza warping
        QImage img;
        if (srcBands >= 3) {
            img = QImage(outWidth, outHeight, QImage::Format_RGB32);
            std::vector<uint8_t> rBuf(outWidth * outHeight);
            std::vector<uint8_t> gBuf(outWidth * outHeight);
            std::vector<uint8_t> bBuf(outWidth * outHeight);
            srcDS->GetRasterBand(1)->RasterIO(GF_Read, 0, 0, srcDS->GetRasterXSize(), srcDS->GetRasterYSize(), rBuf.data(), outWidth, outHeight, GDT_Byte, 0, 0);
            srcDS->GetRasterBand(2)->RasterIO(GF_Read, 0, 0, srcDS->GetRasterXSize(), srcDS->GetRasterYSize(), gBuf.data(), outWidth, outHeight, GDT_Byte, 0, 0);
            srcDS->GetRasterBand(3)->RasterIO(GF_Read, 0, 0, srcDS->GetRasterXSize(), srcDS->GetRasterYSize(), bBuf.data(), outWidth, outHeight, GDT_Byte, 0, 0);
            for (int y = 0; y < outHeight; ++y) {
                QRgb *scanLine = (QRgb*)img.scanLine(y);
                for (int x = 0; x < outWidth; ++x) {
                    int idx = y * outWidth + x;
                    scanLine[x] = qRgb(rBuf[idx], gBuf[idx], bBuf[idx]);
                }
            }
        } else if (srcBands == 1) {
            img = QImage(outWidth, outHeight, QImage::Format_Grayscale8);
            srcDS->GetRasterBand(1)->RasterIO(GF_Read, 0, 0, srcDS->GetRasterXSize(), srcDS->GetRasterYSize(), img.bits(), outWidth, outHeight, GDT_Byte, 0, 0);
        }
        
        GDALClose(srcDS);
        GDALClose(refDS);
        return img;
    }
    
    GDALWarpOptions *warpOptions = GDALCreateWarpOptions();
    warpOptions->hSrcDS = srcDS;
    warpOptions->hDstDS = outDS;
    warpOptions->pTransformerArg = transformArg;
    warpOptions->pfnTransformer = GDALGenImgProjTransform;
    warpOptions->nBandCount = srcBands;
    warpOptions->panSrcBands = (int *)CPLMalloc(sizeof(int) * warpOptions->nBandCount);
    warpOptions->panDstBands = (int *)CPLMalloc(sizeof(int) * warpOptions->nBandCount);
    for (int i = 0; i < warpOptions->nBandCount; i++) {
        warpOptions->panSrcBands[i] = i + 1;
        warpOptions->panDstBands[i] = i + 1;
    }
    
    qDebug() << "Starting warp operation...";
    
    // Esegui warp in un blocco separato per controllare il lifetime di GDALWarpOperation
    {
        GDALWarpOperation warpOp;
        CPLErr warpErr = warpOp.Initialize(warpOptions);
        if (warpErr != CE_None) {
            qWarning() << "Failed to initialize warp operation";
            GDALDestroyGenImgProjTransformer(transformArg);
            GDALClose(srcDS);
            GDALClose(refDS);
            GDALClose(outDS);
            CPLFree(warpOptions->panSrcBands);
            CPLFree(warpOptions->panDstBands);
            GDALDestroyWarpOptions(warpOptions);
            return QImage();
        }
        warpOp.ChunkAndWarpImage(0, 0, outWidth, outHeight);
    }
    qDebug() << "Warp operation completed";

    // Prima leggiamo i dati, poi facciamo cleanup
    qDebug() << "Creating output image...";
    qDebug() << "  Output size:" << outWidth << "x" << outHeight;
    qDebug() << "  Output bands:" << outDS->GetRasterCount();

    // Per immagini binarie/maschera a 1 banda, crea ARGB con nero=trasparente
    QImage img;
    int bands = outDS->GetRasterCount();
    
    if (bands >= 3) {
        qDebug() << "  Reading as RGB...";
        img = QImage(outWidth, outHeight, QImage::Format_RGB32);
        std::vector<uint8_t> rBuf(outWidth * outHeight);
        std::vector<uint8_t> gBuf(outWidth * outHeight);
        std::vector<uint8_t> bBuf(outWidth * outHeight);
        outDS->GetRasterBand(1)->RasterIO(GF_Read, 0, 0, outWidth, outHeight, rBuf.data(), outWidth, outHeight, GDT_Byte, 0, 0);
        outDS->GetRasterBand(2)->RasterIO(GF_Read, 0, 0, outWidth, outHeight, gBuf.data(), outWidth, outHeight, GDT_Byte, 0, 0);
        outDS->GetRasterBand(3)->RasterIO(GF_Read, 0, 0, outWidth, outHeight, bBuf.data(), outWidth, outHeight, GDT_Byte, 0, 0);
        for (int y = 0; y < outHeight; ++y) {
            QRgb *scanLine = (QRgb*)img.scanLine(y);
            for (int x = 0; x < outWidth; ++x) {
                int idx = y * outWidth + x;
                scanLine[x] = qRgb(rBuf[idx], gBuf[idx], bBuf[idx]);
            }
        }
    } else if (bands == 1) {
        // Immagine maschera: nero = trasparente, altri valori = colore basato sul valore
        qDebug() << "  Reading as mask with transparency...";
        img = QImage(outWidth, outHeight, QImage::Format_ARGB32);
        std::vector<uint8_t> buf(outWidth * outHeight);
        outDS->GetRasterBand(1)->RasterIO(GF_Read, 0, 0, outWidth, outHeight, buf.data(), outWidth, outHeight, GDT_Byte, 0, 0);
        for (int y = 0; y < outHeight; ++y) {
            QRgb *scanLine = (QRgb*)img.scanLine(y);
            for (int x = 0; x < outWidth; ++x) {
                int idx = y * outWidth + x;
                uint8_t val = buf[idx];
                if (val == 0) {
                    scanLine[x] = qRgba(0, 0, 0, 0); // trasparente
                } else {
                    scanLine[x] = qRgba(val, val, val, 255); // opaco grigio
                }
            }
        }
    } else {
        qWarning() << "  Unsupported band count:" << bands;
        img = QImage();
    }
    
    qDebug() << "  Output image created:" << img.size();
    
    // Cleanup warp resources dopo aver letto i dati
    qDebug() << "Cleaning up GDAL resources...";
    
    // IMPORTANTE: GDALDestroyWarpOptions NON libera automaticamente pTransformerArg,
    // panSrcBands e panDstBands, quindi dobbiamo farlo manualmente
    // MA dobbiamo impostare pTransformerArg a nullptr prima per evitare problemi
    warpOptions->pTransformerArg = nullptr;
    CPLFree(warpOptions->panSrcBands);
    warpOptions->panSrcBands = nullptr;
    CPLFree(warpOptions->panDstBands);
    warpOptions->panDstBands = nullptr;
    GDALDestroyWarpOptions(warpOptions);
    
    // Ora possiamo distruggere il transformer in sicurezza
    GDALDestroyGenImgProjTransformer(transformArg);
    
    qDebug() << "Closing datasets...";
    GDALClose(outDS);
    GDALClose(srcDS);
    GDALClose(refDS);
    qDebug() << "GDAL cleanup complete";

    return img;
}

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
    QString refPath;
    if (parts.size() > 1) {
        QStringList params = parts[1].split("&");
        for (const QString &param : params) {
            if (param.startsWith("colormap=")) {
                colorMapIndex = param.mid(9).toInt();
            }
            if (param.startsWith("alignTo=")) {
                refPath = QUrl::fromPercentEncoding(param.mid(8).toUtf8());
            }
        }
    }

    qDebug() << "Using colormap index:" << colorMapIndex;
    if (!refPath.isEmpty()) {
        // Pulisci i path da file:/// e decodifica
        QString filePathClean = filePath;
        if (filePathClean.startsWith("file:///")) filePathClean = filePathClean.mid(8);
        else if (filePathClean.startsWith("file://")) filePathClean = filePathClean.mid(7);
        filePathClean = QUrl::fromPercentEncoding(filePathClean.toUtf8());
        QString refPathClean = refPath;
        if (refPathClean.startsWith("file:///")) refPathClean = refPathClean.mid(8);
        else if (refPathClean.startsWith("file://")) refPathClean = refPathClean.mid(7);
        refPathClean = QUrl::fromPercentEncoding(refPathClean.toUtf8());
        qDebug() << "Aligning image to reference:" << refPathClean;
        QImage aligned = GeoTiffProcessor::warpImageToMatch(filePathClean, refPathClean);
        if (size) *size = aligned.size();
        return aligned;
    }

    // Pulisci il path per il caricamento normale
    QString cleanFilePath = filePath;
    if (cleanFilePath.startsWith("file:///")) cleanFilePath = cleanFilePath.mid(8);
    else if (cleanFilePath.startsWith("file://")) cleanFilePath = cleanFilePath.mid(7);
    cleanFilePath = QUrl::fromPercentEncoding(cleanFilePath.toUtf8());
    
    qDebug() << "Loading image from:" << cleanFilePath;
    
    GDALDataset *dataset = (GDALDataset*)GDALOpen(cleanFilePath.toUtf8().constData(), GA_ReadOnly);
    if (dataset == nullptr) {
        qWarning() << "Failed to open GeoTIFF with GDAL:" << cleanFilePath;
        qWarning() << "GDAL Error:" << CPLGetLastErrorMsg();
        return QImage();
    }

    int bandCount = dataset->GetRasterCount();
    int width = dataset->GetRasterXSize();
    int height = dataset->GetRasterYSize();
    
    qDebug() << "Image info - Width:" << width << "Height:" << height << "Bands:" << bandCount;

    // Se l'immagine ha 3+ bande e colormap=-1, carica come RGB
    if (bandCount >= 3 && colorMapIndex == -1) {
        qDebug() << "Loading as RGB image (3 bands)";
        
        // Determine output size
        int outWidth = width;
        int outHeight = height;
        if (requestedSize.width() > 0 && requestedSize.height() > 0) {
            double aspectRatio = (double)width / height;
            outWidth = requestedSize.width();
            outHeight = (int)(outWidth / aspectRatio);
            if (outHeight > requestedSize.height()) {
                outHeight = requestedSize.height();
                outWidth = (int)(outHeight * aspectRatio);
            }
        }
        
        QImage image(outWidth, outHeight, QImage::Format_RGB32);
        
        // Alloca buffer per le 3 bande
        std::vector<uint8_t> rBuf(outWidth * outHeight);
        std::vector<uint8_t> gBuf(outWidth * outHeight);
        std::vector<uint8_t> bBuf(outWidth * outHeight);
        
        // Leggi le 3 bande
        GDALRasterBand *rBand = dataset->GetRasterBand(1);
        GDALRasterBand *gBand = dataset->GetRasterBand(2);
        GDALRasterBand *bBand = dataset->GetRasterBand(3);
        
        rBand->RasterIO(GF_Read, 0, 0, width, height, rBuf.data(), outWidth, outHeight, GDT_Byte, 0, 0);
        gBand->RasterIO(GF_Read, 0, 0, width, height, gBuf.data(), outWidth, outHeight, GDT_Byte, 0, 0);
        bBand->RasterIO(GF_Read, 0, 0, width, height, bBuf.data(), outWidth, outHeight, GDT_Byte, 0, 0);
        
        // Componi l'immagine RGB
        for (int y = 0; y < outHeight; ++y) {
            QRgb *scanLine = (QRgb*)image.scanLine(y);
            for (int x = 0; x < outWidth; ++x) {
                int idx = y * outWidth + x;
                scanLine[x] = qRgb(rBuf[idx], gBuf[idx], bBuf[idx]);
            }
        }
        
        GDALClose(dataset);
        if (size) *size = image.size();
        qDebug() << "RGB image loaded:" << image.size();
        return image;
    }

    // Single band processing (colormap mode)
    // Get the first band
    GDALRasterBand *band = dataset->GetRasterBand(1);
    if (band == nullptr) {
        qWarning() << "No raster band found";
        GDALClose(dataset);
        return QImage();
    }

    // Usa width e height già dichiarati sopra
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

QVariantList GeoTiffProcessor::getHistogramData(const QString &imagePath, int bins)
{
    QVariantList result;
    
    if (imagePath.isEmpty()) {
        return result;
    }
    
    GDALDataset *dataset = (GDALDataset*)GDALOpen(imagePath.toUtf8().constData(), GA_ReadOnly);
    if (dataset == nullptr) {
        qWarning() << "Failed to open GeoTIFF for histogram:" << imagePath;
        return result;
    }
    
    GDALRasterBand *band = dataset->GetRasterBand(1);
    if (band == nullptr) {
        qWarning() << "No raster band found for histogram";
        GDALClose(dataset);
        return result;
    }
    
    int width = band->GetXSize();
    int height = band->GetYSize();
    int pixelCount = width * height;
    
    // Read all data
    std::vector<float> data(pixelCount);
    CPLErr err = band->RasterIO(GF_Read, 0, 0, width, height, data.data(), width, height, GDT_Float32, 0, 0);
    
    if (err != CE_None) {
        qWarning() << "Failed to read raster data for histogram";
        GDALClose(dataset);
        return result;
    }
    
    // Filter valid data (NaN, infinite, and -9999)
    std::vector<float> validData;
    for (int i = 0; i < pixelCount; ++i) {
        float value = data[i];
        if (!std::isnan(value) && !std::isinf(value) && value != -9999.0f) {
            validData.push_back(value);
        }
    }
    
    if (validData.empty()) {
        GDALClose(dataset);
        return result;
    }
    
    // Sort data to calculate percentiles
    std::sort(validData.begin(), validData.end());
    
    // Calculate quartiles for IQR method
    int n = validData.size();
    int q1_idx = n / 4;
    int q3_idx = 3 * n / 4;
    float q1 = validData[q1_idx];
    float q3 = validData[q3_idx];
    float iqr = q3 - q1;
    
    // Define upper bound
    float upperBound = q3 + 1.5f * iqr;
    
    qDebug() << "Histogram outlier removal:";
    qDebug() << "  Total valid data points:" << n;
    qDebug() << "  Q1 index:" << q1_idx << "value:" << q1;
    qDebug() << "  Q3 index:" << q3_idx << "value:" << q3;
    qDebug() << "  IQR:" << iqr;
    qDebug() << "  Upper bound (Q3 + 1.5*IQR):" << upperBound;
    qDebug() << "  Data range:" << validData.front() << "to" << validData.back();
    
    // Filter data above upper bound
    std::vector<float> filteredData;
    int removedCount = 0;
    for (float value : validData) {
        if (value <= upperBound) {
            filteredData.push_back(value);
        } else {
            removedCount++;
        }
    }
    
    qDebug() << "  Original data points:" << validData.size() 
             << "Removed (> upper bound):" << removedCount
             << "After filtering:" << filteredData.size();
    
    if (filteredData.empty()) {
        GDALClose(dataset);
        return result;
    }
    
    // Get min/max from filtered data
    float minVal = filteredData.front();
    float maxVal = filteredData.back();
    
    if (maxVal <= minVal) {
        maxVal = minVal + 1.0f;
    }
    
    // Create histogram bins
    std::vector<int> histogram(bins, 0);
    
    // Build histogram from filtered data
    for (float value : filteredData) {
        double normalized = (value - minVal) / (maxVal - minVal);
        normalized = std::max(0.0, std::min(1.0, normalized));
        
        int binIndex = static_cast<int>(normalized * (bins - 1));
        binIndex = std::max(0, std::min(bins - 1, binIndex));
        histogram[binIndex]++;
    }
    
    // Find outlier bins by IQR method on bin counts
    std::vector<int> binCounts;
    for (int count : histogram) {
        if (count > 0) {
            binCounts.push_back(count);
        }
    }
    
    if (!binCounts.empty()) {
        std::sort(binCounts.begin(), binCounts.end());
        int n_bins = binCounts.size();
        int q1_idx = n_bins / 4;
        int q3_idx = 3 * n_bins / 4;
        int q1_count = binCounts[q1_idx];
        int q3_count = binCounts[q3_idx];
        int iqr_count = q3_count - q1_count;
        int upper_bound_count = q3_count + 3 * iqr_count;  // More aggressive: 3x instead of 1.5x
        
        qDebug() << "Histogram bin count filtering:";
        qDebug() << "  Non-empty bins:" << n_bins;
        qDebug() << "  Q1 count:" << q1_count << "Q3 count:" << q3_count << "IQR:" << iqr_count;
        qDebug() << "  Upper bound for bin counts:" << upper_bound_count;
        
        // Remove anomalous bin peaks
        int removedBins = 0;
        for (int i = 0; i < bins; ++i) {
            if (histogram[i] > upper_bound_count) {
                qDebug() << "  Removing bin" << i << "with count" << histogram[i];
                histogram[i] = 0;
                removedBins++;
            }
        }
        qDebug() << "  Removed" << removedBins << "anomalous bins";
    }
    
    // Find max count for normalization (after removing outliers)
    int maxCount = 0;
    for (int count : histogram) {
        maxCount = std::max(maxCount, count);
    }
    
    // Build result
    for (int i = 0; i < bins; ++i) {
        double binValue = minVal + (i / (double)(bins - 1)) * (maxVal - minVal);
        double normalizedCount = maxCount > 0 ? histogram[i] / (double)maxCount : 0.0;
        
        QVariantMap bin;
        bin["index"] = i;
        bin["value"] = binValue;
        bin["count"] = histogram[i];
        bin["normalized"] = normalizedCount;
        
        result.append(bin);
    }
    
    GDALClose(dataset);
    
    qDebug() << "Generated histogram with" << bins << "bins (NaN/inf and upper outliers removed)";
    return result;
}
