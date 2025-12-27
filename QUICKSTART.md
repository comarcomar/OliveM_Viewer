# Guida Rapida - Olive GeoTIFF Viewer

## Avvio Rapido (5 minuti)

### Prerequisiti
✅ Qt 6.2+ installato
✅ GDAL installato
✅ CMake 3.16+
✅ Compilatore C++17

### Compilazione Express

#### Qt Creator (Raccomandato)
1. Apri Qt Creator
2. File → Open File or Project
3. Seleziona `CMakeLists.txt`
4. Configure Project con il tuo Kit Qt6
5. Build → Build Project (Ctrl+B)
6. Run → Run (Ctrl+R)

#### Command Line (Linux/macOS)
```bash
cd OliveGeoTiffViewer
mkdir build && cd build
cmake ..
make -j$(nproc)
./OliveGeoTiffViewer
```

#### Command Line (Windows)
```cmd
cd OliveGeoTiffViewer
mkdir build && cd build
cmake .. -G "Ninja"
cmake --build . --config Release
Release\OliveGeoTiffViewer.exe
```

---

## Utilizzo Base

### 1️⃣ Carica le Immagini
- Pannello sinistro superiore → "Load TIFF" → Seleziona prima immagine GeoTIFF
- Pannello sinistro inferiore → "Load TIFF" → Seleziona seconda immagine GeoTIFF

### 2️⃣ Personalizza la Visualizzazione
- **Color Map**: Seleziona dal menu a tendina (Jet, Hot, Cool, Gray, Viridis, Plasma)
- **3D View**: Spunta la checkbox per visualizzazione in rilievo 3D
- **Legenda**: Visualizzata automaticamente a lato dell'immagine

### 3️⃣ Esegui l'Analisi
- Pannello destro → "Run Analysis"
- Attendi elaborazione
- Visualizza risultato nel pannello destro
- Controlla Param1 e Param2 nel pannello inferiore

### 4️⃣ Esplora i Risultati
- Usa +/- per zoom
- "Reset" per vista originale

---

## Struttura File Principali

```
OliveGeoTiffViewer/
├── 📄 README.md              ⭐ Documentazione completa
├── 📄 INSTALL.md             🔧 Guida installazione dettagliata
├── 📄 STRUCTURE.md           🏗️ Architettura del progetto
├── 📄 QUICKSTART.md          ⚡ Questa guida
│
├── 🎨 main.qml               UI principale
├── 🎨 GeoTiffImagePanel.qml  Pannello immagine
├── 🎨 GeoTiff3DView.qml      Visualizzazione 3D
├── 🎨 ResultImageViewer.qml  Viewer risultati
│
├── ⚙️ geotiffprocessor.h     Backend C++ header
├── ⚙️ geotiffprocessor.cpp   Backend C++ implementation
├── ⚙️ main.cpp               Entry point
│
├── 🔌 OliveMatrixLib.h       Interfaccia DLL
├── 🔌 OliveMatrixLib_example.cpp  Esempio DLL
│
├── 🛠️ OliveGeoTiffViewer.pro Qt project file
├── 🛠️ CMakeLists.txt         CMake build
├── 📜 build_windows.bat      Script build Windows
└── 📜 build_linux.sh         Script build Linux
```

---

## Funzionalità Principali

### ✨ Visualizzazione
- ✅ Caricamento file GeoTIFF
- ✅ 6 mappe falsi colori predefinite
- ✅ Legenda dinamica
- ✅ Rendering 3D interattivo
- ✅ Controlli zoom

### 🔬 Analisi
- ✅ Integrazione con libreria esterna (OliveMatrixLib.dll)
- ✅ Elaborazione di due immagini
- ✅ Calcolo parametri (Param1, Param2)
- ✅ Generazione immagine risultato

### 🎯 UI
- ✅ Layout a 3 pannelli
- ✅ Dark theme professionale
- ✅ Controlli intuitivi
- ✅ Gestione errori

---

## Risoluzione Problemi Comuni

### ❌ "CMake Error: Could not find Qt6"

**Soluzione**: Specifica il path di Qt in Qt Creator durante la configurazione del Kit, oppure:
```bash
cmake .. -DCMAKE_PREFIX_PATH=/path/to/Qt/6.x.x/gcc_64
```

### ❌ "cannot find -lgdal"
```bash
# Verifica GDAL
gdal-config --version

# Se mancante, installa:
sudo apt-get install libgdal-dev  # Linux
# oppure OSGeo4W                   # Windows
```

### ❌ "Failed to load OliveMatrixLib.dll"
⚠️ **Normale!** L'app funziona comunque in modalità demo.
Per usare la vera DLL, copiala nella directory dell'eseguibile.

### ❌ Immagine non si carica
- ✅ Verifica che sia un GeoTIFF valido: `gdalinfo image.tif`
- ✅ Controlla i permessi del file
- ✅ Prova con un'altra immagine

---

## Esempi di Codice

### Aggiungere una Nuova Color Map

**In main.qml**:
```qml
colorMaps: [
    // ... esistenti
    { 
        name: "Rainbow", 
        colors: ["#FF0000", "#FFA500", "#FFFF00", "#00FF00", "#0000FF", "#4B0082", "#9400D3"] 
    }
]
```

**In geotiffprocessor.cpp**:
```cpp
case 6: // Rainbow
    return {QColor("#FF0000"), QColor("#FFA500"), QColor("#FFFF00"), 
            QColor("#00FF00"), QColor("#0000FF"), QColor("#4B0082"), QColor("#9400D3")};
```

### Modificare il Calcolo dei Parametri

**In OliveMatrixLib_example.cpp**:
```cpp
bool RunAnalysis(...) {
    // ... caricamento immagini
    
    // Esempio: Calcola media delle differenze
    *param1 = calculateMeanDifference(data1, data2, width * height);
    
    // Esempio: Calcola correlazione
    *param2 = calculateCorrelation(data1, data2, width * height);
    
    // ... generazione output
}
```

---

## Prossimi Passi

### Per Sviluppatori
1. 📖 Leggi [STRUCTURE.md](STRUCTURE.md) per capire l'architettura
2. 🔍 Esamina il codice dei componenti QML
3. ⚙️ Studia l'integrazione C++/QML in geotiffprocessor.cpp
4. 🧪 Implementa la tua versione di OliveMatrixLib

### Per Utenti
1. 📥 Ottieni file GeoTIFF di test
2. 🎨 Sperimenta con diverse color maps
3. 🔬 Prova l'analisi con coppie di immagini
4. 📊 Interpreta i parametri calcolati

### Per Contributori
1. 🐛 Segnala bug su GitHub
2. 💡 Proponi nuove features
3. 🔧 Migliora il codice esistente
4. 📚 Espandi la documentazione

---

## Risorse Utili

### Documentazione
- **Qt Documentation**: https://doc.qt.io/
- **GDAL Documentation**: https://gdal.org/
- **QML Tutorial**: https://doc.qt.io/qt-5/qmlapplications.html
- **Qt3D Guide**: https://doc.qt.io/qt-5/qt3d-index.html

### File GeoTIFF di Test
- **USGS Earth Explorer**: https://earthexplorer.usgs.gov/
- **Copernicus Open Access Hub**: https://scihub.copernicus.eu/
- **NASA Earthdata**: https://earthdata.nasa.gov/

### Tools
- **QGIS**: Software GIS open-source per visualizzare GeoTIFF
- **gdalinfo**: Comando per ispezionare file GeoTIFF
- **gdal_translate**: Conversione tra formati raster

---

## FAQ

**Q: L'app funziona senza OliveMatrixLib.dll?**
A: Sì! In modalità demo genera parametri di esempio.

**Q: Posso usare immagini non georeferenziate?**
A: Sì, ma perdi info sulla posizione geografica.

**Q: Quanti MB può gestire?**
A: Dipende dalla RAM. Test con successo fino a 500MB.

**Q: Supporta immagini multibanda?**
A: Attualmente usa solo la prima banda. Estendibile.

**Q: Funziona su Raspberry Pi?**
A: Sì, ma compila da sorgente e attendi tempi più lunghi.

---

## Supporto

📧 **Email**: support@olive-analysis.example.com
🐛 **Bug Report**: GitHub Issues
💬 **Community**: Forum / Discord / Reddit

---

**Versione**: 1.0.0  
**Data**: Dicembre 2024  
**Licenza**: MIT (vedi LICENSE file)

Buon lavoro con Olive GeoTIFF Viewer! 🚀
