# Modifiche Apportate - OM Tree Crown Segmentation Tool

## File Modificati

### 1. main.qml
**Modifiche principali**:
- ✅ Titolo finestra cambiato in "OM Tree Crown Segmentation Tool"
- ✅ Aggiunto supporto temi (Chiaro/Scuro)
- ✅ Toolbar con pulsanti Settings e Reset
- ✅ Pannello input (Shapefile e RGB Orthophoto)
- ✅ Settings dialog con:
  - Opzione tema (Chiaro/Scuro)
  - Checkbox "Denoise" (default: checked)
  - Slider "Area Threshold" (5-500, default: 70)
- ✅ Pannelli rinominati: "Ortofoto DSM" e "Ortofoto NDVI"
- ✅ ColorMaps ridotte (rimossi Cool e Plasma)
- ✅ Visualizzazione RGB orthophoto nel pannello destro
- ✅ Funzione resetSystem() per reset completo

### 2. GeoTiffImagePanel.qml
**Modifiche principali**:
- ✅ Controlli zoom in toolbar
- ✅ Finestra detached funzionante con controlli zoom
- ✅ ComboBox colormap ridotta a 150px con preview
- ✅ Preview colormap in ogni item del dropdown
- ✅ Integrazione con ColorLegend component

### 3. ColorLegend.qml (NUOVO)
**Funzionalità**:
- ✅ Larghezza ridotta (30px invece di 60px)
- ✅ Visualizzazione valori: Min, Max e 3 intermedi
- ✅ Formattazione intelligente valori (k per migliaia)
- ✅ Tick marks per valori intermedi

### 4. ImageViewerContent.qml
**Modifiche principali**:
- ✅ Timer per nascondere istruzioni dopo 5 secondi
- ✅ Smooth: false per caricamento più veloce
- ✅ Istruzioni (scroll/drag) si nascondono automaticamente
- ✅ Property hideInstructionsDelay configurabile

### 5. ResultImageViewer.qml
**Modifiche principali**:
- ✅ Supporto displayPath per RGB orthophoto
- ✅ Compatibilità con risultati analisi

### 6. qml.qrc
- ✅ Aggiunto ColorLegend.qml

## Modifiche Ancora da Fare

### Backend C++ (geotiffprocessor.cpp)

#### 1. Ottimizzazione Caricamento Immagini
**File**: geotiffprocessor.cpp, funzione `requestImage()`

**Modifiche suggerite**:
```cpp
// Aggiungi downsampling più aggressivo per preview
int maxDimension = 2048; // Limita dimensione massima
if (width > maxDimension || height > maxDimension) {
    double scale = std::min((double)maxDimension / width, 
                           (double)maxDimension / height);
    outWidth = (int)(width * scale);
    outHeight = (int)(height * scale);
}

// Usa nearest neighbor per preview rapida
CPLErr err = band->RasterIO(
    GF_Read,
    0, 0, width, height,
    buffer, outWidth, outHeight,
    GDT_Float32,
    0, 0,
    nullptr  // Use default resampling
);

// Considera caching della prima preview
static QMap<QString, QImage> imageCache;
if (imageCache.contains(filePath)) {
    return imageCache[filePath];
}
```

#### 2. Statistiche per ColorLegend
**Aggiungi metodo per esporre statistiche a QML**:

```cpp
// In geotiffprocessor.h
class GeoTiffProcessor : public QObject {
    ...
    Q_INVOKABLE QVariantMap getImageStatistics(const QString &path);
};

// In geotiffprocessor.cpp
QVariantMap GeoTiffProcessor::getImageStatistics(const QString &path) {
    GDALDataset *dataset = (GDALDataset*)GDALOpen(path.toUtf8(), GA_ReadOnly);
    if (!dataset) return QVariantMap();
    
    GDALRasterBand *band = dataset->GetRasterBand(1);
    double minVal, maxVal, mean, stdDev;
    band->ComputeStatistics(false, &minVal, &maxVal, &mean, &stdDev, nullptr, nullptr);
    
    QVariantMap stats;
    stats["min"] = minVal;
    stats["max"] = maxVal;
    stats["mean"] = mean;
    stats["stdDev"] = stdDev;
    
    GDALClose(dataset);
    return stats;
}
```

**In QML poi puoi usare**:
```qml
// In ColorLegend.qml
Component.onCompleted: {
    var stats = processor.getImageStatistics(root.imagePath)
    minValue = stats.min
    maxValue = stats.max
}
```

### 3D View (GeoTiff3DView.qml)

**File da modificare completamente**. La visualizzazione 3D attuale non usa i valori reali. 

**Approccio consigliato**:
1. Leggi i valori del DSM dal GeoTIFF
2. Crea una geometry custom con altezze proporzionali
3. Usa Qt Quick 3D Model con geometry procedurale

**Problema**: Qt Quick 3D non supporta facilmente heightmaps procedurali. 

**Soluzioni**:
1. **Opzione A**: Genera mesh OBJ da GeoTIFF in C++, caricalo in Qt Quick 3D
2. **Opzione B**: Usa Custom Geometry in Qt Quick 3D 
3. **Opzione C**: Esporta heightmap come texture, usa shader per displacement

**Raccomandazione**: Per la complessità richiesta, suggerisco di implementare Opzione A:

```cpp
// Nuovo metodo in geotiffprocessor.cpp
bool GeoTiffProcessor::generateHeightmapMesh(const QString &geoTiffPath, const QString &objOutputPath) {
    // 1. Apri GeoTIFF
    // 2. Leggi valori elevazione
    // 3. Genera vertici con Z = valore elevazione (scalato)
    // 4. Genera faces (triangoli)
    // 5. Scrivi file OBJ
    // 6. Return true se successo
}
```

Poi in QML:
```qml
Model {
    source: generatedMeshPath  // Path to .obj file
    materials: PrincipledMaterial { ... }
}
```

## File da Testare

1. **main.qml** - Toolbar, settings, theme switching
2. **GeoTiffImagePanel.qml** - Detached window, colormap preview
3. **ColorLegend.qml** - Valori corretti
4. **ImageViewerContent.qml** - Timer istruzioni
5. **ResultImageViewer.qml** - RGB display

## Note Implementazione

### Tema Chiaro
I colori sono definiti come properties in main.qml:
- backgroundColor: "#e8f4f8" (azzurro molto tenue)
- panelColor: "#ffffff" (bianco)
- borderColor: "#b0d4e0" (azzurro chiaro)
- textColor: "#1a1a1a" (quasi nero)
- buttonColor: "#4a90e2" (blu)

### Settings
Persistenza settings non implementata. Per implementare:
```qml
Settings {
    property bool darkTheme: true
    property bool denoise: true
    property int areaThreshold: 70
}
```

### Performance
- Smooth: false riduce qualità ma accelera rendering
- Downsampling immagini grandi raccomandato
- Cache preview per immagini già caricate

## Compilazione

```bash
cd OliveGeoTiffViewer
mkdir build && cd build
cmake ..
cmake --build . --config Release
```

Tutti i nuovi file QML sono inclusi in qml.qrc e saranno compilati automaticamente.
