#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include "geotiffprocessor.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    
    // Set application information
    app.setApplicationName("Olive GeoTIFF Viewer");
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
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    
    engine.load(url);
    
    if (engine.rootObjects().isEmpty())
        return -1;
    
    return app.exec();
}
