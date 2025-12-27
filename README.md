# Olive GeoTIFF Analysis Viewer

> **Versione Qt 6** - Per la versione Qt 5, vedi branch `qt5-legacy`

Un'applicazione QtQuick professionale per la visualizzazione e l'analisi di immagini GeoTIFF con supporto per mappe falsi colori, visualizzazione 3D e analisi tramite libreria esterna.

## Caratteristiche Principali

### Interfaccia Utente
- **Layout a tre riquadri**:
  - Riquadro sinistro: Due pannelli verticali per il caricamento e visualizzazione di immagini GeoTIFF
  - Riquadro destro: Visualizzazione del risultato dell'analisi
  - Riquadro inferiore: Display dei parametri calcolati (Param1 e Param2)

### Funzionalità per le Immagini

#### Caricamento Immagini
- Supporto completo per file GeoTIFF (.tif, .tiff)
- Dialog di selezione file integrato
- Validazione automatica del formato
- Supporto per georeferenziazione GDAL

#### Visualizzazione Mappe Falsi Colori
Sei mappe colori predefinite:
1. **Jet**: Colormap scientifica classica (blu → rosso)
2. **Hot**: Scala termica (nero → rosso → giallo → bianco)
3. **Cool**: Scala fredda (ciano → magenta)
4. **Gray**: Scala di grigi
5. **Viridis**: Colormap percettivamente uniforme
6. **Plasma**: Colormap ad alto contrasto

Ogni mappa include:
- Legenda laterale con gradiente
- Indicatori min/max
- Applicazione in tempo reale

#### Visualizzazione 3D
- Rendering 3D del rilievo topografico (usando **Qt Quick 3D**)
- Controlli orbitali interattivi:
  - Drag per rotazione
  - Scroll per zoom
  - Illuminazione PBR (Physically Based Rendering)
- Griglia di riferimento
- Materiali realistici

### Analisi e Elaborazione

#### Integrazione con OliveMatrixLib
L'applicazione si integra con una DLL esterna (OliveMatrixLib.dll) che espone la funzione:

```cpp
bool RunAnalysis(
    const char* image1Path,
    const char* image2Path,
    char* outputPath,
    double* param1,
    double* param2
);
```

**Funzionalità**:
- Caricamento dinamico della DLL
- Validazione della presenza di entrambe le immagini
- Esecuzione asincrona dell'analisi
- Gestione errori robusta
- Fallback per testing senza DLL

#### Visualizzazione Risultati
- Display automatico dell'immagine risultante
- Controlli zoom (+ / - / Reset)
- Evidenziazione quando il risultato è disponibile
- Indicatori di stato durante il caricamento

#### Parametri Calcolati
- Visualizzazione in tempo reale di Param1 e Param2
- Display numerico con 4 decimali
- Colore verde per evidenziare i valori
- Pannelli con bordi luminosi

## Requisiti di Sistema

### Dipendenze Software
- **Qt 6.2+** (raccomandato Qt 6.5+ o 6.8 LTS)
  - QtQuick
  - QtQuick.Controls
  - QtQuick3D (sostituisce Qt3D)
  - QtQuick.Dialogs
- **GDAL 3.x** (Geospatial Data Abstraction Library)
- **C++17** compiler
  - Windows: Visual Studio 2022 (raccomandato) o 2019
  - Linux: GCC 9+ o Clang 10+
  - macOS: Apple Clang 12+

### Librerie Esterne
- **OliveMatrixLib.dll** (opzionale, con fallback per testing)

## Installazione

### 1. Installazione GDAL

#### Windows (OSGeo4W)
```bash
# Scarica e installa OSGeo4W da https://trac.osgeo.org/osgeo4w/
# Seleziona GDAL durante l'installazione
```

#### Linux (Ubuntu/Debian)
```bash
sudo apt-get update
sudo apt-get install gdal-bin libgdal-dev
```

#### macOS (Homebrew)
```bash
brew install gdal
```

### 2. Installazione Qt
Scarica Qt da https://www.qt.io/download oppure usa un package manager:

```bash
# Ubuntu 22.04+ (Qt 6 disponibile nei repository)
sudo apt-get install qt6-base-dev qt6-declarative-dev qt6-quick3d-dev

# Ubuntu 20.04 (richiede PPA o installer online)
# Usa Qt Online Installer da qt.io

# macOS
brew install qt@6
```

### 3. Compilazione del Progetto

```bash
cd OliveGeoTiffViewer
qmake OliveGeoTiffViewer.pro
make
```

O usa Qt Creator:
1. Apri `OliveGeoTiffViewer.pro` in Qt Creator
2. Configura il kit di compilazione
3. Build → Build Project

### 4. Configurazione OliveMatrixLib

Crea o copia `OliveMatrixLib.dll` nella directory dell'eseguibile. Se non disponibile, l'applicazione userà un fallback per testing.

## Utilizzo

### Avvio dell'Applicazione
```bash
./OliveGeoTiffViewer  # Linux/macOS
OliveGeoTiffViewer.exe  # Windows
```

### Workflow Tipico

1. **Carica le Immagini**
   - Clicca "Load TIFF" nel pannello Image 1
   - Seleziona il primo file GeoTIFF
   - Ripeti per Image 2

2. **Configura la Visualizzazione**
   - Seleziona una colormap dal menu a tendina
   - Opzionalmente, attiva "3D View" per il rilievo

3. **Esegui l'Analisi**
   - Clicca "Run Analysis" nel pannello destro
   - Attendi il completamento
   - Visualizza i risultati e i parametri

4. **Esplora i Risultati**
   - Usa zoom +/- per dettagliare l'immagine risultato
   - Verifica Param1 e Param2 nel pannello inferiore

## Architettura del Codice

### Struttura dei File

```
OliveGeoTiffViewer/
├── main.cpp                      # Entry point dell'applicazione
├── main.qml                      # Layout principale
├── GeoTiffImagePanel.qml         # Componente pannello immagine
├── GeoTiff3DView.qml            # Visualizzazione 3D
├── ResultImageViewer.qml        # Viewer risultati
├── geotiffprocessor.h           # Header processore C++
├── geotiffprocessor.cpp         # Implementazione processore
├── OliveMatrixLib.h             # Header interfaccia DLL
├── OliveMatrixLib_example.cpp   # Implementazione esempio DLL
├── OliveGeoTiffViewer.pro       # Qt project file
├── qml.qrc                      # Qt resources
└── README.md                    # Questa documentazione
```

### Componenti Principali

#### 1. GeoTiffProcessor (C++)
Classe Qt che gestisce:
- Caricamento e validazione GeoTIFF via GDAL
- Interfacciamento con OliveMatrixLib.dll
- Signals/slots per comunicazione QML
- Image provider per rendering con colormap

#### 2. GeoTiffImageProvider (C++)
QQuickImageProvider custom che:
- Legge dati GeoTIFF con GDAL
- Normalizza i valori
- Applica le colormap
- Fornisce immagini a QML

#### 3. GeoTiffImagePanel (QML)
Componente riusabile che include:
- Pulsante caricamento file
- Area di visualizzazione immagine
- Selettore colormap
- Toggle 2D/3D
- Legenda colori

#### 4. GeoTiff3DView (QML)
Componente 3D con:
- Scene3D e Entity hierarchy
- Camera orbitale
- Mesh plane per il terreno
- Illuminazione
- Materiali Phong

## Personalizzazione

### Aggiungere Nuove Colormap

In `main.qml`, aggiungi alla property `colorMaps`:

```qml
colorMaps: [
    // ... existing maps
    { name: "CustomMap", colors: ["#color1", "#color2", "#color3"] }
]
```

E in `geotiffprocessor.cpp`, nel metodo `getColorMapColors()`:

```cpp
case 6: // CustomMap
    return {QColor("#color1"), QColor("#color2"), QColor("#color3")};
```

### Modificare la Risoluzione del Mesh 3D

In `GeoTiff3DView.qml`, modifica:

```qml
PlaneMesh {
    id: terrainMesh
    width: 20.0
    height: 20.0
    meshResolution: Qt.size(200, 200)  // Aumenta per più dettagli
}
```

### Personalizzare i Parametri Visualizzati

Nel riquadro inferiore di `main.qml`, aggiungi nuovi Rectangle con Label per parametri aggiuntivi.

## Implementazione della DLL OliveMatrixLib

### Interfaccia Richiesta

```cpp
extern "C" {
    __declspec(dllexport) bool RunAnalysis(
        const char* image1Path,
        const char* image2Path,
        char* outputPath,      // Buffer di almeno 1024 bytes
        double* param1,
        double* param2
    );
}
```

### Esempio di Implementazione

Vedi `OliveMatrixLib_example.cpp` per un'implementazione di riferimento che:
- Carica due GeoTIFF con GDAL
- Calcola la differenza normalizzata
- Genera un'immagine risultato
- Calcola parametri statistici

### Compilazione della DLL

#### Windows (MSVC)
```bash
cl /LD /DOLIVEMATRIXLIB_EXPORTS OliveMatrixLib_example.cpp /I"C:/OSGeo4W64/include" /link /LIBPATH:"C:/OSGeo4W64/lib" gdal_i.lib
```

#### Windows (MinGW)
```bash
g++ -shared -DOLIVEMATRIXLIB_EXPORTS -o OliveMatrixLib.dll OliveMatrixLib_example.cpp -I"C:/OSGeo4W64/include" -L"C:/OSGeo4W64/lib" -lgdal_i
```

## Troubleshooting

### Problema: "Failed to load OliveMatrixLib.dll"
**Soluzione**: 
- Verifica che la DLL sia nella stessa directory dell'eseguibile
- Su Windows, verifica le dipendenze con Dependency Walker
- L'app funzionerà comunque in modalità fallback

### Problema: "Failed to open GeoTIFF"
**Soluzione**:
- Verifica che GDAL sia correttamente installato
- Controlla che il file sia un GeoTIFF valido
- Verifica i permessi di lettura del file

### Problema: "No raster bands found"
**Soluzione**:
- Il file potrebbe essere corrotto
- Usa `gdalinfo` per verificare il file:
  ```bash
  gdalinfo image.tif
  ```

### Problema: Rendering 3D non funziona
**Soluzione**:
- Verifica che Qt3D sia installato
- Controlla i driver OpenGL
- Alcuni sistemi potrebbero richiedere ANGLE o Mesa

### Problema: Le colormap non si applicano
**Soluzione**:
- L'image provider potrebbe non essere registrato correttamente
- Verifica i log di Qt per messaggi di errore
- Controlla che l'URL dell'immagine sia nel formato corretto

## Performance

### Ottimizzazioni Consigliate

1. **Immagini Grandi**: Per GeoTIFF > 50MB, considera:
   - Downsampling durante il caricamento
   - Tiles/pyramid per zoom progressivo
   - Caching delle immagini elaborate

2. **Rendering 3D**: Per dataset ad alta risoluzione:
   - Riduci `meshResolution` per prestazioni migliori
   - Usa LOD (Level of Detail) per grandi aree
   - Implementa culling delle facce

3. **Colormap**: Le operazioni sono CPU-intensive:
   - Implementa caching delle colormap
   - Usa GPU shaders per applicazione in tempo reale
   - Pre-genera texture per colormap comuni

## Estensioni Future

### Funzionalità Pianificate
- [ ] Supporto multi-banda (RGB, multispectral)
- [ ] Export dei risultati in vari formati
- [ ] Strumenti di misura e annotazione
- [ ] Istogrammi e statistiche avanzate
- [ ] Batch processing
- [ ] Plugin system per analisi custom
- [ ] Supporto per formati raster addizionali
- [ ] Overlay di shapefiles vettoriali

### Miglioramenti UI
- [ ] Temi personalizzabili
- [ ] Workspace salvabili
- [ ] Shortcuts da tastiera
- [ ] Timeline per sequenze temporali
- [ ] Comparazione side-by-side migliorata

## Licenza

Questo progetto è fornito come esempio educativo. Verifica le licenze di:
- Qt (GPL/LGPL/Commercial)
- GDAL (MIT/X style)
- OliveMatrixLib (proprietaria)

## Supporto e Contributi

Per bug report, feature requests, o contributi:
1. Apri un issue su GitHub
2. Fornisci log dettagliati
3. Includi versioni di Qt e GDAL
4. Specifica il sistema operativo

## Contatti

- **Progetto**: Olive GeoTIFF Analysis Viewer
- **Versione**: 1.0.0
- **Data**: 2024

---

**Note**: Questa applicazione è stata sviluppata per dimostrare l'integrazione di Qt, GDAL, e analisi GIS custom. È intesa come punto di partenza per applicazioni GIS professionali e può essere estesa secondo le necessità specifiche del progetto.
