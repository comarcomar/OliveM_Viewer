# Note di Migrazione Qt 5 → Qt 6

Questo documento descrive le modifiche apportate per aggiornare l'applicazione da Qt 5 a Qt 6.

## Modifiche Principali

### 1. Import QML

#### Prima (Qt 5)
```qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.3
import Qt.labs.platform 1.1
```

#### Dopo (Qt 6)
```qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
```

**Nota**: Qt 6 non richiede più la specifica della versione negli import.

---

### 2. Qt 3D → Qt Quick 3D

La più grande modifica è stata la sostituzione di Qt 3D con Qt Quick 3D.

#### Prima (Qt 5 con Qt3D)
```qml
import QtQuick.Scene3D 2.15
import Qt3D.Core 2.15
import Qt3D.Render 2.15
import Qt3D.Extras 2.15

Scene3D {
    Entity {
        Camera { }
        OrbitCameraController { }
        PlaneMesh { }
        PhongMaterial { }
    }
}
```

#### Dopo (Qt 6 con QtQuick3D)
```qml
import QtQuick3D
import QtQuick3D.Helpers

View3D {
    PerspectiveCamera { }
    DirectionalLight { }
    Model {
        source: "#Rectangle"
        materials: PrincipledMaterial { }
    }
}
```

**Vantaggi Qt Quick 3D**:
- ✅ Prestazioni migliori
- ✅ API più semplice
- ✅ Migliore integrazione con QtQuick
- ✅ Supporto PBR (Physically Based Rendering)
- ✅ Controllo camera più intuitivo

---

### 3. FileDialog

#### Prima (Qt 5)
```qml
import Qt.labs.platform 1.1 as Labs

Labs.FileDialog {
    fileMode: Labs.FileDialog.OpenFile
    onAccepted: {
        var path = file.toString()
    }
}
```

#### Dopo (Qt 6)
```qml
import QtQuick.Dialogs

FileDialog {
    fileMode: FileDialog.OpenFile
    onAccepted: {
        var path = selectedFile.toString()
    }
}
```

**Nota**: `file` è stato rinominato in `selectedFile`.

---

### 4. Dialog

#### Prima (Qt 5)
```qml
Dialog {
    standardButtons: Dialog.Ok
}
```

#### Dopo (Qt 6)
```qml
Dialog {
    standardButtons: Dialog.Ok
    modal: true
    anchors.centerIn: parent
}
```

**Nota**: In Qt 6, è consigliato impostare esplicitamente `modal: true`.

---

### 5. main.cpp

#### Prima (Qt 5)
```cpp
#include <QGuiApplication>

int main(int argc, char *argv[]) {
    QGuiApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QGuiApplication app(argc, argv);
    // ...
}
```

#### Dopo (Qt 6)
```cpp
#include <QGuiApplication>

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    // High DPI è abilitato automaticamente in Qt 6
    // ...
}
```

**Nota**: `Qt::AA_EnableHighDpiScaling` non è più necessario in Qt 6.

---

### 6. File di Progetto (.pro)

#### Prima (Qt 5)
```qmake
QT += quick qml quickcontrols2 3dcore 3drender 3dinput 3dextras
```

#### Dopo (Qt 6)
```qmake
QT += quick qml quickcontrols2 quick3d
```

---

### 7. CMakeLists.txt

#### Prima (Qt 5)
```cmake
find_package(Qt5 REQUIRED COMPONENTS
    Core Quick Qml QuickControls2
    3DCore 3DRender 3DInput 3DExtras
)

target_link_libraries(${PROJECT_NAME} PRIVATE
    Qt5::Core Qt5::Quick Qt5::Qml
    Qt5::3DCore Qt5::3DRender Qt5::3DInput Qt5::3DExtras
)
```

#### Dopo (Qt 6)
```cmake
find_package(Qt6 REQUIRED COMPONENTS
    Core Quick Qml QuickControls2 Quick3D
)

target_link_libraries(${PROJECT_NAME} PRIVATE
    Qt6::Core Qt6::Quick Qt6::Qml
    Qt6::QuickControls2 Qt6::Quick3D
)
```

---

## Controllo Camera 3D

### Qt 5 (Qt3D)
```qml
OrbitCameraController {
    camera: camera
    linearSpeed: 50.0
    lookSpeed: 180.0
}
```

### Qt 6 (QtQuick3D)
```qml
// Opzione 1: WasdController (built-in)
WasdController {
    controlledObject: camera
    speed: 0.5
}

// Opzione 2: Custom con MouseArea
MouseArea {
    onPositionChanged: {
        camera.eulerRotation.y += deltaX * 0.5
        camera.eulerRotation.x += deltaY * 0.5
    }
    onWheel: {
        camera.position.z += delta
    }
}
```

---

## Materiali

### Qt 5 (Qt3D)
```qml
PhongMaterial {
    ambient: Qt.rgba(0.3, 0.5, 0.3, 1.0)
    diffuse: Qt.rgba(0.4, 0.7, 0.4, 1.0)
    specular: Qt.rgba(0.1, 0.1, 0.1, 1.0)
    shininess: 20.0
}
```

### Qt 6 (QtQuick3D)
```qml
PrincipledMaterial {
    baseColor: "#4a7a4a"
    metalness: 0.0
    roughness: 0.8
}
```

**Nota**: `PrincipledMaterial` usa un workflow PBR moderno, più realistico.

---

## Illuminazione

### Qt 5 (Qt3D)
```qml
Entity {
    components: [
        DirectionalLight {
            color: "white"
            worldDirection: Qt.vector3d(-0.5, -1.0, -0.5)
            intensity: 0.7
        }
    ]
}
```

### Qt 6 (QtQuick3D)
```qml
DirectionalLight {
    eulerRotation.x: -30
    eulerRotation.y: -70
    brightness: 1.0
    castsShadow: true
}
```

---

## Geometria

### Qt 5 (Qt3D)
```qml
Entity {
    PlaneMesh {
        width: 20.0
        height: 20.0
        meshResolution: Qt.size(100, 100)
    }
}
```

### Qt 6 (QtQuick3D)
```qml
Model {
    source: "#Rectangle"  // Built-in primitive
    scale: Qt.vector3d(20, 1, 20)
}
```

**Geometrie built-in Qt Quick 3D**:
- `#Rectangle`
- `#Sphere`
- `#Cube`
- `#Cone`
- `#Cylinder`

---

## Installazione Pacchetti

### Ubuntu 22.04+
```bash
# Qt 5
sudo apt-get install qt5-default qtdeclarative5-dev qt3d5-dev

# Qt 6
sudo apt-get install qt6-base-dev qt6-declarative-dev qt6-quick3d-dev
```

### Windows
```
Qt 5: Seleziona "Qt 3D" nell'installer
Qt 6: Seleziona "Qt Quick 3D" nell'installer
```

### macOS
```bash
# Qt 5
brew install qt@5

# Qt 6
brew install qt@6
```

---

## Problemi Comuni e Soluzioni

### ❌ "module QtQuick.Scene3D is not installed"
**Causa**: Stai usando Qt 6 con import Qt 5.
**Soluzione**: Usa `import QtQuick3D` invece di `import QtQuick.Scene3D`.

### ❌ "Cannot find -lQt5::3DCore"
**Causa**: CMake cerca Qt 5 ma hai Qt 6.
**Soluzione**: Cambia `find_package(Qt5` in `find_package(Qt6`.

### ❌ "Type OrbitCameraController unavailable"
**Causa**: OrbitCameraController non esiste in QtQuick3D.
**Soluzione**: Usa `WasdController` o implementa controlli custom con MouseArea.

### ❌ FileDialog property 'file' not found
**Causa**: In Qt 6 si chiama `selectedFile`.
**Soluzione**: Cambia `file` in `selectedFile`.

---

## Compatibilità Retroattiva

Se vuoi mantenere compatibilità con Qt 5:

```qml
// Detect Qt version
readonly property bool isQt6: typeof(Qt.application.version) !== 'undefined' 
                               && Qt.application.version.split('.')[0] >= 6

// Conditional import (non supportato direttamente)
// Soluzione: crea due file separati e carica quello corretto
```

**Raccomandazione**: Per nuovi progetti, usa solo Qt 6. È più moderno e supportato.

---

## Checklist Migrazione

- [x] Aggiornare tutti gli import QML (rimuovere versioni)
- [x] Sostituire Qt3D con QtQuick3D
- [x] Cambiare `Scene3D` → `View3D`
- [x] Cambiare `Entity` → `Model` / `Node`
- [x] Aggiornare materiali (Phong → Principled)
- [x] Aggiornare controlli camera
- [x] Cambiare `file` → `selectedFile` in FileDialog
- [x] Rimuovere `Qt::AA_EnableHighDpiScaling` da main.cpp
- [x] Aggiornare .pro file (3d* → quick3d)
- [x] Aggiornare CMakeLists.txt (Qt5 → Qt6)
- [x] Testare su tutte le piattaforme
- [x] Aggiornare documentazione

---

## Performance

### Qt 5 (Qt3D)
- Rendering: OpenGL-based
- Performance: Buona ma overhead Entity system
- Mobile: Supporto limitato

### Qt 6 (QtQuick3D)
- Rendering: OpenGL / Vulkan / Metal / Direct3D
- Performance: Ottimizzato, meno overhead
- Mobile: Ottimo supporto

**Risultato**: Qt 6 con QtQuick3D è generalmente più veloce e fluido.

---

## Risorse Aggiuntive

### Documentazione Ufficiale
- **Qt 6 Migration Guide**: https://doc.qt.io/qt-6/portingguide.html
- **Qt Quick 3D**: https://doc.qt.io/qt-6/qtquick3d-index.html
- **Qt Quick 3D Examples**: https://doc.qt.io/qt-6/qtquick3d-examples.html

### Esempi
```bash
# Dopo aver installato Qt 6, gli esempi sono in:
# Linux: /usr/share/qt6/examples/quick3d/
# Windows: C:\Qt\6.5.0\Examples\Qt-6.5.0\quick3d\
# macOS: /Applications/Qt/Examples/Qt-6.5.0/quick3d/
```

---

## Conclusione

La migrazione da Qt 5 a Qt 6 comporta principalmente:

1. **Aggiornamento import QML** (semplice, nessuna versione)
2. **Sostituzione Qt3D con QtQuick3D** (richiede riscrittura componente 3D)
3. **Piccole modifiche API** (FileDialog, Dialog, etc.)

I benefici includono:
- ✅ Prestazioni migliori
- ✅ API più moderne
- ✅ Miglior supporto futuro
- ✅ Rendering più realistico (PBR)

**Raccomandazione**: Usa Qt 6 per tutti i nuovi progetti!

---

**Versione documento**: 1.0  
**Data**: Dicembre 2024  
**Applicabile a**: Olive GeoTIFF Viewer 1.0.0
