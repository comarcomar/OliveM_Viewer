#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QDebug>
#include <QImageReader>
#include "geotiffprocessor.h"
#include <gdal_priv.h>

int main(int argc, char *argv[])
{
    // Increase image allocation limit for large GeoTIFF files
    // Default is 256 MB, increase to 2 GB for high-resolution imagery
    QImageReader::setAllocationLimit(2048);  // 2048 MB = 2 GB
    
    QGuiApplication app(argc, argv);
    
    // Initialize GDAL (uses system GDAL from C:\Sviluppo\gdal\bin via PATH)
    GDALAllRegister();
    qDebug() << "GDAL initialized, version:" << GDALVersionInfo("VERSION_NUM");
    
    // Set application information
    app.setApplicationName("OM Tree Crown Segmentation Tool");
    app.setOrganizationName("OliveAnalysis");
    app.setApplicationVersion("1.0.0");
    
    // Set style
    QQuickStyle::setStyle("Fusion");
    
    // Register types
    qmlRegisterType<GeoTiffProcessor>("GeoTiffProcessor", 1, 0, "GeoTiffProcessor");
    
    QQmlApplicationEngine engine;
    
    // Add image provider
    engine.addImageProvider("geotiff", new GeoTiffImageProvider());
    
    // Load main QML file
    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            qCritical() << "Failed to load QML file:" << url;
            QCoreApplication::exit(-1);
        }
    }, Qt::QueuedConnection);
    
    engine.load(url);
    
    if (engine.rootObjects().isEmpty()) {
        qCritical() << "No root objects loaded!";
        return -1;
    }
    
    qDebug() << "Application started successfully";
    
    return app.exec();
}

