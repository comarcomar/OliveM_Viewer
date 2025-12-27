QT += quick qml quickcontrols2 quick3d

CONFIG += c++17

# You can make your code fail to compile if it uses deprecated APIs.
DEFINES += QT_DEPRECATED_WARNINGS

# GDAL library configuration
# Adjust these paths according to your GDAL installation
win32 {
    INCLUDEPATH += "C:/OSGeo4W64/include"
    LIBS += -L"C:/OSGeo4W64/lib" -lgdal_i
}

unix {
    CONFIG += link_pkgconfig
    PKGCONFIG += gdal
}

SOURCES += \
    main.cpp \
    geotiffprocessor.cpp

HEADERS += \
    geotiffprocessor.h

RESOURCES += qml.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

# Default rules for deployment
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

# Copy OliveMatrixLib.dll to output directory (Windows)
win32 {
    OLIVE_DLL = $$PWD/OliveMatrixLib.dll
    
    CONFIG(debug, debug|release) {
        DESTDIR = $$OUT_PWD/debug
    } else {
        DESTDIR = $$OUT_PWD/release
    }
    
    # Copy DLL if it exists
    exists($$OLIVE_DLL) {
        QMAKE_POST_LINK += $$QMAKE_COPY \"$$shell_path($$OLIVE_DLL)\" \"$$shell_path($$DESTDIR)\" $$escape_expand(\\n\\t)
    }
}
