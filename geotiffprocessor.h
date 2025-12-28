#ifndef GEOTIFFPROCESSOR_H
#define GEOTIFFPROCESSOR_H

#include <QObject>
#include <QString>
#include <QImage>
#include <gdal_priv.h>

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
    // Reset method to clear all loaded images and state
    void reset();

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
