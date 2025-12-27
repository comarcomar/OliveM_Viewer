#ifndef GEOTIFFPROCESSOR_H
#define GEOTIFFPROCESSOR_H

#include <QObject>
#include <QString>
#include <QImage>
#include <QQuickImageProvider>
#include <QThread>

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
    void runAnalysis();

signals:
    void imagesChanged();
    void analysisCompleted(const QString &resultPath, double param1, double param2);
    void errorOccurred(const QString &errorMessage);

private:
    QString m_image1Path;
    QString m_image2Path;
    bool m_hasImage1;
    bool m_hasImage2;

    // Load GeoTIFF and validate
    bool loadGeoTiff(const QString &path);
    
    // Call external DLL function
    bool callRunAnalysis(const QString &image1, const QString &image2, 
                         QString &outputPath, double &param1, double &param2);
};

// Image provider for displaying GeoTIFF with color maps
class GeoTiffImageProvider : public QQuickImageProvider
{
public:
    GeoTiffImageProvider();
    
    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override;

private:
    QImage applyColorMap(const QImage &grayscale, int colorMapIndex);
    QVector<QColor> getColorMapColors(int index);
};

#endif // GEOTIFFPROCESSOR_H
