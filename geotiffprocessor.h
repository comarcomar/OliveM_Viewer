#ifndef GEOTIFFPROCESSOR_H
#define GEOTIFFPROCESSOR_H

#include <QObject>
#include <QString>
#include <QImage>
#include <QQuickImageProvider>
#include <QThread>
#include <QVariantMap>

// Forward declaration for GDAL
class GDALDataset;

class GeoTiffProcessor : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool hasValidImages READ hasValidImages NOTIFY imagesChanged)

public:
    explicit GeoTiffProcessor(QObject *parent = nullptr);
    ~GeoTiffProcessor();

    bool hasValidImages() const;

public slots:
    void setImage1(const QString &path);
    void setImage2(const QString &path);
    void setShapefileZip(const QString &path);
    void runAnalysis();
    void setDenoiseFlag(bool enabled);
    void setAreaThreshold(int threshold);
    QVariantMap getImageStatistics(const QString &imagePath);
    QVariantList getHeightData(const QString &imagePath, int maxWidth, int maxHeight);
    void clearCache();

signals:
    void imagesChanged();
    void analysisCompleted(const QString &resultPath, double fCov, double meanNdvi);
    void errorOccurred(const QString &errorMessage);

private:
    QString m_image1Path;
    QString m_image2Path;
    QString m_shapefileZipPath;
    bool m_hasImage1;
    bool m_hasImage2;
    bool m_denoiseFlag;
    int m_areaThreshold;

    // Load GeoTIFF and validate
    bool loadGeoTiff(const QString &path);
    
    // Call external DLL function
    bool callRunAnalysis(const QString &dsmPath, const QString &ndviPath, 
                         const QString &shapefileZip, QString &outputPath, 
                         double &fCov, double &meanNdvi);
};

// Image provider for displaying GeoTIFF with color maps
class GeoTiffImageProvider : public QQuickImageProvider
{
public:
    GeoTiffImageProvider();
    
    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override;

private:
    QVector<QColor> getColorMapColors(int index);
};

#endif // GEOTIFFPROCESSOR_H
