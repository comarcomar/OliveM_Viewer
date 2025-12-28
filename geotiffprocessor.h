<<<<<<< HEAD
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
    void runAnalysis();
    QVariantMap getImageStatistics(const QString &imagePath);
    QVariantList getHeightData(const QString &imagePath, int maxWidth, int maxHeight);
    void clearCache();

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
    QVector<QColor> getColorMapColors(int index);
};

#endif // GEOTIFFPROCESSOR_H
=======
#ifndef GEOTIFFPROCESSOR_H
#define GEOTIFFPROCESSOR_H

#include <QObject>
#include <QString>
#include <QImage>
<<<<<<< HEAD
#include <QQuickImageProvider>
#include <QThread>
#include <QVariantMap>

// Forward declaration for GDAL
class GDALDataset;
=======
#include <gdal_priv.h>
>>>>>>> c7b3856baee19c6fe1f00054241d88c0e7d57791

class GeoTiffProcessor : public QObject
{
    Q_OBJECT

public:
    explicit GeoTiffProcessor(QObject *parent = nullptr);
    ~GeoTiffProcessor();

    // Methods to load and process GeoTIFF images
    bool loadImage1(const QString &filePath);
    bool loadImage2(const QString &filePath);
    
    // Getters
    QString getImage1Path() const { return m_image1Path; }
    QString getImage2Path() const { return m_image2Path; }
    bool hasImage1() const { return m_hasImage1; }
    bool hasImage2() const { return m_hasImage2; }
    QImage getImage1() const { return m_image1; }
    QImage getImage2() const { return m_image2; }

public slots:
<<<<<<< HEAD
    void setImage1(const QString &path);
    void setImage2(const QString &path);
    void runAnalysis();
    QVariantMap getImageStatistics(const QString &imagePath);
    QVariantList getHeightData(const QString &imagePath, int maxWidth, int maxHeight);
    void clearCache();
=======
    // Reset method to clear all loaded images and state
    void reset();
>>>>>>> c7b3856baee19c6fe1f00054241d88c0e7d57791

signals:
    void imagesChanged();
    void errorOccurred(const QString &errorMessage);

private:
    // Private cleanup method to close open GDAL datasets
    void cleanup();

    // Member variables
    QString m_image1Path;
    QString m_image2Path;
    bool m_hasImage1;
    bool m_hasImage2;
    QImage m_image1;
    QImage m_image2;
    
    // GDAL dataset pointers
    GDALDataset *m_dataset1;
    GDALDataset *m_dataset2;
};

#endif // GEOTIFFPROCESSOR_H
>>>>>>> e47cf4cea6b4501618ea2e73f2c206964939faf2
