# Struttura del Progetto - Olive GeoTIFF Viewer

## Panoramica

```
OliveGeoTiffViewer/
├── QML Components/           # Interfaccia utente QtQuick
├── C++ Backend/              # Logica di business e GDAL
├── Configuration/            # File di progetto e build
├── Documentation/            # Guide e documentazione
└── External/                 # Librerie esterne
```

## Struttura Dettagliata dei File 

```
OliveGeoTiffViewer/
│
├── main.cpp                          # Entry point dell'applicazione
│   ├── Inizializzazione QGuiApplication
│   ├── Registrazione tipi QML
│   ├── Setup image provider
│   └── Caricamento QML engine
│
├── main.qml                          # Layout principale dell'applicazione
│   ├── ApplicationWindow
│   ├── Gestione layout a 3 pannelli
│   ├── Integrazione GeoTiffProcessor
│   ├── Definizione color maps
│   └── Display parametri analisi
│
├── GeoTiffImagePanel.qml            # Componente pannello immagine
│   ├── Controlli caricamento file
│   ├── Viewer 2D immagine
│   ├── Integrazione 3D view
│   ├── Selettore color map
│   └── Legenda colori
│
├── GeoTiff3DView.qml                # Visualizzazione 3D
│   ├── Scene3D setup
│   ├── Camera orbitale
│   ├── Mesh terreno
│   ├── Illuminazione
│   └── Controlli interattivi
│
├── ResultImageViewer.qml            # Viewer risultati analisi
│   ├── Display immagine risultato
│   ├── Controlli zoom
│   ├── Indicatori stato
│   └── Gestione aggiornamenti
│
├── geotiffprocessor.h               # Header processore C++
│   ├── Classe GeoTiffProcessor
│   │   ├── Properties
│   │   ├── Public slots
│   │   ├── Signals
│   │   └── Private methods
│   └── Classe GeoTiffImageProvider
│       ├── requestImage()
│       └── Color mapping
│
├── geotiffprocessor.cpp             # Implementazione processore
│   ├── GeoTiffProcessor
│   │   ├── Inizializzazione GDAL
│   │   ├── Caricamento immagini
│   │   ├── Validazione GeoTIFF
│   │   ├── Interfaccia con DLL
│   │   └── Gestione analisi
│   └── GeoTiffImageProvider
│       ├── Lettura raster GDAL
│       ├── Normalizzazione valori
│       ├── Applicazione color map
│       └── Generazione immagine
│
├── OliveMatrixLib.h                 # Interfaccia DLL esterna
│   ├── Definizione API
│   ├── Export/Import macros
│   └── Signature RunAnalysis()
│
├── OliveMatrixLib_example.cpp       # Implementazione esempio DLL
│   ├── Caricamento immagini GDAL
│   ├── Algoritmo analisi
│   ├── Calcolo parametri
│   └── Generazione output
│
├── OliveGeoTiffViewer.pro           # Qt project file (qmake)
│   ├── Configurazione Qt modules
│   ├── Path GDAL
│   ├── Opzioni compilatore
│   └── Post-build commands
│
├── CMakeLists.txt                   # CMake build configuration
│   ├── Requisiti minimi
│   ├── Find packages
│   ├── Target configuration
│   └── Installation rules
│
├── qml.qrc                          # Qt resource file
│   └── QML files embedding
│
├── build_windows.bat                # Script build Windows
├── build_linux.sh                   # Script build Linux
│
├── README.md                        # Documentazione principale
│   ├── Features overview
│   ├── Installation guide
│   ├── Usage instructions
│   ├── Architecture details
│   └── Customization guide
│
├── INSTALL.md                       # Guida installazione dettagliata
│   ├── Requisiti sistema
│   ├── Istruzioni per OS
│   ├── Configurazione librerie
│   └── Troubleshooting
│
└── STRUCTURE.md                     # Questo file
    └── Documentazione struttura progetto
```

## Descrizione Componenti

### Frontend QML

#### 1. main.qml
**Responsabilità**:
- Layout principale a 3 pannelli (sinistra, destra, inferiore)
- Orchestrazione componenti
- Gestione stato applicazione
- Definizione color maps
- Display parametri di analisi

**Connessioni**:
```
main.qml
├── → GeoTiffImagePanel (x2)
├── → ResultImageViewer
├── → GeoTiffProcessor (C++ backend)
└── → Dialog (error handling)
```

#### 2. GeoTiffImagePanel.qml
**Responsabilità**:
- UI per caricamento file GeoTIFF
- Display immagine con image provider
- Gestione color map
- Toggle 2D/3D view
- Legenda colori

**Proprietà esposte**:
```qml
property string panelTitle
property var colorMaps
property string imagePath
property int currentColorMap
property bool show3D
```

**Signals**:
```qml
signal imageChanged(string imagePath)
```

#### 3. GeoTiff3DView.qml
**Responsabilità**:
- Rendering 3D del rilievo
- Camera orbitale
- Mesh heightmap
- Sistema illuminazione
- UI overlay

**Tecnologie**:
- Qt3D Scene3D
- OrbitCameraController
- PlaneMesh per terreno
- PhongMaterial

#### 4. ResultImageViewer.qml
**Responsabilità**:
- Display immagine risultato
- Controlli zoom interattivi
- Indicatori di caricamento
- Gestione cache

**Funzioni**:
```qml
function updateImage(path)
```

### Backend C++

#### 1. GeoTiffProcessor
**Responsabilità principale**: Bridge tra QML e GDAL/DLL

**Membri privati**:
```cpp
QString m_image1Path;
QString m_image2Path;
bool m_hasImage1;
bool m_hasImage2;
```

**Metodi pubblici**:
```cpp
// Properties
bool hasValidImages() const;

// Slots
void setImage1(const QString &path);
void setImage2(const QString &path);
void runAnalysis();

// Signals
void imagesChanged();
void analysisCompleted(QString resultPath, double param1, double param2);
void errorOccurred(QString errorMessage);
```

**Metodi privati**:
```cpp
bool loadGeoTiff(const QString &path);
bool callRunAnalysis(const QString &image1, 
                     const QString &image2,
                     QString &outputPath, 
                     double &param1, 
                     double &param2);
```

**Flusso di esecuzione**:
```
QML: Load Image 1 → setImage1()
                  ↓
              loadGeoTiff() → GDAL validation
                  ↓
              emit imagesChanged()
                  ↓
QML: Load Image 2 → setImage2()
                  ↓
              loadGeoTiff()
                  ↓
              emit imagesChanged()
                  ↓
QML: Run Analysis → runAnalysis()
                  ↓
              callRunAnalysis() → Load DLL
                  ↓                   ↓
              Call RunAnalysis()      ↓
                  ↓                   ↓
              Get results             ↓
                  ↓                   ↓
              emit analysisCompleted()
                  ↓
QML: Update UI with results
```

#### 2. GeoTiffImageProvider
**Responsabilità**: Fornire immagini QML con color mapping

**Metodi**:
```cpp
QImage requestImage(const QString &id, 
                   QSize *size, 
                   const QSize &requestedSize);

QImage applyColorMap(const QImage &grayscale, 
                     int colorMapIndex);

QVector<QColor> getColorMapColors(int index);
```

**ID format**: `"path/to/file.tif?colormap=0"`

**Pipeline di processing**:
```
Request → Parse ID → Open GDAL dataset
              ↓
         Read raster band
              ↓
         Normalize values (min/max)
              ↓
         Create grayscale QImage
              ↓
         Apply color map
              ↓
         Return colored QImage
```

### External Interface

#### OliveMatrixLib API

**Function signature**:
```cpp
extern "C" {
    bool RunAnalysis(
        const char* image1Path,    // Input: path prima immagine
        const char* image2Path,    // Input: path seconda immagine
        char* outputPath,          // Output: path risultato (buffer 1024 bytes)
        double* param1,            // Output: primo parametro
        double* param2             // Output: secondo parametro
    );
}
```

**Contratto**:
- Ritorna `true` se successo, `false` se errore
- `outputPath` deve contenere path completo al file risultato
- `param1` e `param2` contengono valori calcolati
- Thread-safe (se implementato correttamente)

**Esempio implementazione**:
```cpp
bool RunAnalysis(...) {
    // 1. Validazione input
    // 2. Apertura GeoTIFF con GDAL
    // 3. Verifica dimensioni compatibili
    // 4. Lettura dati raster
    // 5. Algoritmo di analisi
    // 6. Calcolo parametri
    // 7. Generazione output GeoTIFF
    // 8. Scrittura file
    // 9. Return success
}
```

## Flusso Dati

### Caricamento Immagine
```
User Action (Click "Load TIFF")
    ↓
FileDialog.open()
    ↓
User selects file
    ↓
GeoTiffImagePanel.imageChanged(path)
    ↓
main.qml receives signal
    ↓
processor.setImage1(path) or setImage2(path)
    ↓
GeoTiffProcessor.loadGeoTiff(path)
    ↓
GDAL validation
    ↓
emit imagesChanged()
    ↓
QML updates button states
    ↓
Image displayed via GeoTiffImageProvider
```

### Cambio Color Map
```
User changes ComboBox
    ↓
currentColorMap property updated
    ↓
Image.source URL changes
    ↓
GeoTiffImageProvider.requestImage() called
    ↓
Parse colormap index from URL
    ↓
Apply new color map
    ↓
Return new QImage
    ↓
Image displayed
```

### Esecuzione Analisi
```
User clicks "Run Analysis"
    ↓
processor.runAnalysis()
    ↓
Validate both images loaded
    ↓
callRunAnalysis()
    ↓
Load OliveMatrixLib.dll
    ↓
Resolve RunAnalysis function
    ↓
Call external function
    ↓
Wait for completion
    ↓
Receive output path + params
    ↓
emit analysisCompleted(path, param1, param2)
    ↓
QML receives signal
    ↓
Update ResultImageViewer
    ↓
Update parameter displays
```

### Toggle 3D View
```
User checks "3D View"
    ↓
show3D property = true
    ↓
Image.visible = false
    ↓
GeoTiff3DView.visible = true
    ↓
Scene3D initialization
    ↓
Load heightmap data
    ↓
Create mesh geometry
    ↓
Apply materials
    ↓
Setup camera
    ↓
Render 3D scene
```

## Pattern di Design

### 1. Model-View-ViewModel (MVVM)
- **Model**: GeoTiffProcessor, GDAL datasets
- **View**: QML components
- **ViewModel**: Qt properties, signals/slots

### 2. Provider Pattern
- `GeoTiffImageProvider` decouples image loading da UI
- Caching automatico Qt
- Lazy loading

### 3. Signal-Slot Pattern
- Comunicazione asincrona C++ ↔ QML
- Event-driven architecture
- Loose coupling

### 4. Dependency Injection
- `colorMaps` property injected in panels
- Processor instance shared

### 5. Factory Pattern
- QML component instantiation
- Image provider registration

## Threading Model

### Main Thread (GUI Thread)
- Gestione UI
- Event loop Qt
- QML rendering

### GDAL Operations
- Attualmente sul main thread
- Potenziale ottimizzazione: worker threads

### Possibili miglioramenti:
```cpp
class GeoTiffLoader : public QThread {
    void run() override {
        // Load and process GDAL in background
        emit imageReady(image);
    }
};
```

## Gestione Memoria

### Ownership
- QML objects: QML engine
- C++ objects registrati: manual o parent ownership
- GDAL datasets: manual close (GDALClose)

### Lifecycle
```
Application Start
    ↓
Create QGuiApplication
    ↓
Register types with QML engine
    ↓
Load main.qml
    ↓
QML engine creates objects
    ↓
User interacts
    ↓
Load/process/analyze images
    ↓
Application Close
    ↓
QML engine destroys objects
    ↓
C++ destructors called
    ↓
GDAL cleanup
```

### Memory Leaks da evitare
- Non chiudere GDAL datasets
- QImage copies non necessarie
- Accumulo texture in GPU

## Estensibilità

### Aggiungere nuovi tipi di analisi
1. Estendi interfaccia DLL con nuove funzioni
2. Aggiungi wrapper methods in GeoTiffProcessor
3. Aggiungi UI controls in QML
4. Connect signals/slots

### Aggiungere nuovi formati
1. GDAL supporta 200+ formati
2. Nessuna modifica codice necessaria
3. Basta FileDialog filter update

### Aggiungere nuove visualizzazioni
1. Crea nuovo componente QML
2. Integra in layout main.qml
3. Connect a processor backend

## Testing Strategy

### Unit Tests (C++)
```cpp
// test_geotiffprocessor.cpp
TEST(GeoTiffProcessor, LoadValidImage) {
    GeoTiffProcessor proc;
    EXPECT_TRUE(proc.loadGeoTiff("test.tif"));
}
```

### Integration Tests (QML)
```qml
// tst_mainwindow.qml
TestCase {
    name: "MainWindow"
    
    function test_loadImages() {
        // Test image loading flow
    }
}
```

### Manual Testing
- [ ] Load various GeoTIFF formats
- [ ] Test all color maps
- [ ] Verify 3D rendering
- [ ] Run analysis with DLL
- [ ] Test error conditions

## Build Process

### qmake Pipeline
```
qmake OliveGeoTiffViewer.pro
    ↓
Generate Makefile
    ↓
Parse .pro file
    ↓
Resolve dependencies
    ↓
Configure include paths
    ↓
make/nmake
    ↓
Compile C++ sources
    ↓
MOC processing
    ↓
RCC resource compilation
    ↓
Link executable
    ↓
Post-build (copy DLLs)
```

### CMake Pipeline
```
cmake ..
    ↓
Find Qt packages
    ↓
Find GDAL package
    ↓
Generate build files
    ↓
make
    ↓
Compile → Link → Install
```

## Deployment

### Windows
```
Build → windeployqt → Copy GDAL DLLs → Copy OliveMatrixLib.dll → Package
```

### Linux
```
Build → ldd check → Copy .so files → Create AppImage/deb
```

### macOS
```
Build → macdeployqt → Create .app bundle → Sign → Create .dmg
```

---

**Manutenzione**: Questo documento dovrebbe essere aggiornato quando:
- Vengono aggiunti nuovi componenti
- Cambia l'architettura
- Vengono aggiunte nuove dipendenze
- Cambiano i pattern di design

**Versione documento**: 1.0
**Ultima modifica**: 2024
