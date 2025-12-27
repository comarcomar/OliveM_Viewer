# Troubleshooting - Caricamento Immagini TIFF

Questa guida risolve i problemi comuni nel caricamento delle immagini GeoTIFF.

## ✅ Verifiche Preliminari

### 1. Verifica GDAL Installation
```bash
# Windows
gdalinfo --version

# Linux/macOS
gdal-config --version
```

**Output atteso**: `GDAL 3.x.x, released 20XX/XX/XX`

### 2. Test Immagine TIFF
```bash
gdalinfo your_image.tif
```

**Cosa verificare**:
- ✅ File aperto senza errori
- ✅ "Driver: GTiff/GeoTIFF"
- ✅ "Size is XXX, YYY" (dimensioni valide)
- ✅ "Band 1" presente

### 3. Verifica Percorso File
- ✅ Il path NON deve contenere caratteri speciali (`, ", ', spazi problematici)
- ✅ Su Windows, usa `C:\path\to\file.tif` non `C:/path/to/file.tif` se possibile
- ✅ Non usare path relativi, sempre assoluti

---

## 🔍 Debug del Caricamento

### Abilitare Log Dettagliati

**Windows**:
```cmd
set QT_LOGGING_RULES="*.debug=true"
OliveGeoTiffViewer.exe
```

**Linux/macOS**:
```bash
QT_LOGGING_RULES="*.debug=true" ./OliveGeoTiffViewer
```

### Output da Verificare
```
GeoTiffImageProvider::requestImage called with id: ...
Decoded file path: /full/path/to/image.tif
Using colormap index: 0
Opening GeoTIFF: /full/path/to/image.tif
GDAL dataset opened successfully
Raster size: 1024 x 768
Number of bands: 1
Band info - Width: 1024 Height: 768 Type: 6
Raster data read successfully
Statistics - Min: 0.0 Max: 255.0 Mean: 127.5 StdDev: 50.3
Image generation complete: QSize(1024, 768)
```

---

## ❌ Errori Comuni e Soluzioni

### Errore: "File does not exist"

**Sintomo**:
```
File does not exist: /path/to/image.tif
```

**Causa**: Path errato o file non accessibile

**Soluzione**:
1. Verifica che il file esista realmente
2. Controlla i permessi di lettura
3. Su Windows, verifica che non sia bloccato dal sistema
4. Prova a copiare il file in una directory semplice tipo `C:\temp\test.tif`

---

### Errore: "Failed to open GeoTIFF with GDAL"

**Sintomo**:
```
Failed to open GeoTIFF with GDAL: /path/to/image.tif
GDAL Error: not recognized as a supported file format
```

**Causa**: File non è un GeoTIFF valido o GDAL driver non disponibile

**Soluzione**:
```bash
# Verifica il file
file image.tif  # Linux/macOS
# Dovrebbe mostrare: "TIFF image data"

# Converti in GeoTIFF standard se necessario
gdal_translate -of GTiff input.tif output.tif

# Verifica driver GTiff disponibili
gdalinfo --formats | grep GTiff
```

---

### Errore: "No raster band found"

**Sintomo**:
```
No raster band found
```

**Causa**: File TIFF senza bande raster (es. TIFF vuoto)

**Soluzione**:
```bash
# Verifica numero bande
gdalinfo image.tif | grep "Band"

# Output atteso:
# Band 1 Block=1024x1 Type=Byte...
```

Se non ci sono bande, il file è corrotto o non è un raster.

---

### Errore: "Failed to read raster data"

**Sintomo**:
```
Failed to read raster data: GDAL Error message
```

**Causa**: Dati raster corrotti o formato non supportato

**Soluzione**:
```bash
# Ricostruisci il file
gdal_translate -co "TILED=YES" -co "COMPRESS=LZW" input.tif output.tif

# Prova a leggere con gdalinfo
gdalinfo -stats output.tif
```

---

### Errore: "Invalid statistics"

**Sintomo**:
```
Invalid statistics, computing from buffer
Statistics - Min: nan Max: nan Mean: nan StdDev: nan
```

**Causa**: File contiene solo valori NoData o NaN

**Soluzione**:
```bash
# Verifica valori NoData
gdalinfo image.tif | grep "NoData"

# Rimuovi valori NoData
gdal_translate -a_nodata none input.tif output.tif

# Oppure specifica un valore valido
gdal_translate -a_nodata 0 input.tif output.tif
```

---

### Errore: Immagine Nera/Vuota Visualizzata

**Sintomo**: Immagine caricata ma appare completamente nera

**Causa**: Range valori troppo stretto o valori tutti uguali

**Debug**:
1. Controlla i log per `Statistics - Min:... Max:...`
2. Se Min == Max, il file ha valori uniformi

**Soluzione**:
```bash
# Verifica statistiche
gdalinfo -stats image.tif

# Riscala i valori
gdal_translate -scale 0 1000 0 255 -ot Byte input.tif output.tif
```

---

### Errore: "Image status: 3" (Error)

**Sintomo in QML**:
```
Image status: 3 for path: /path/to/image.tif
Failed to load image: /path/to/image.tif
```

**Causa**: Image provider ha restituito QImage vuota

**Debug**:
1. Verifica logs C++ per errori precedenti
2. Controlla che GDAL sia correttamente inizializzato
3. Verifica che il path sia decodificato correttamente

**Soluzione**:
```cpp
// In main.cpp, verifica GDAL init
GDALAllRegister();
qDebug() << "GDAL version:" << GDALVersionInfo("VERSION_NUM");
```

---

## 🛠️ Fix Specifici per Tipo di File

### TIFF con Compressione

Alcuni TIFF compressi potrebbero non caricarsi:

```bash
# Decomprimi
gdal_translate -co "COMPRESS=NONE" input.tif output.tif
```

### TIFF Multi-banda

L'app usa solo la prima banda:

```bash
# Estrai banda specifica
gdal_translate -b 2 input.tif output.tif  # Usa banda 2

# Crea composito RGB
gdal_merge.py -separate -o output.tif band1.tif band2.tif band3.tif
```

### TIFF con Georeferencing Complesso

```bash
# Semplifica proiezione
gdalwarp -t_srs EPSG:4326 input.tif output.tif
```

### TIFF molto Grandi (>500MB)

```bash
# Crea overview per caricamento veloce
gdaladdo -r average image.tif 2 4 8 16

# Oppure ridimensiona
gdal_translate -outsize 50% 50% input.tif output.tif
```

---

## 🔧 Configurazione Ambiente

### Windows - PATH GDAL

Se GDAL non viene trovato:

```cmd
# Aggiungi a PATH sistema
setx PATH "%PATH%;C:\OSGeo4W64\bin"

# Verifica
where gdal*.dll
```

### Linux - GDAL Library

```bash
# Verifica library path
ldconfig -p | grep gdal

# Se mancante
export LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH

# Permanente
echo 'export LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
```

### GDAL Data Files

Se errori tipo "Can't open EPSG support file":

```bash
# Windows
set GDAL_DATA=C:\OSGeo4W64\share\gdal

# Linux/macOS
export GDAL_DATA=/usr/share/gdal
```

---

## 📋 Checklist Completa

Prima di segnalare un bug, verifica:

- [ ] `gdalinfo --version` funziona
- [ ] `gdalinfo image.tif` apre il file senza errori
- [ ] Il file è in formato GeoTIFF (non solo TIFF generico)
- [ ] Il path non contiene caratteri speciali
- [ ] I log dell'applicazione sono abilitati (`QT_LOGGING_RULES="*.debug=true"`)
- [ ] Hai provato con un file TIFF semplice di test
- [ ] Il file non è troppo grande (>2GB)
- [ ] Hai verificato permessi lettura file
- [ ] Su Windows, hai eseguito come Amministratore se necessario

---

## 🧪 File di Test

Crea un TIFF di test valido:

```bash
# Crea raster di test 512x512
gdal_create -of GTiff -outsize 512 512 -bands 1 -burn 128 -ot Byte test.tif

# Oppure scarica dati di test
# USGS Earth Explorer: https://earthexplorer.usgs.gov/
# Copernicus: https://scihub.copernicus.eu/
```

---

## 🐛 Segnalazione Bug

Se il problema persiste, apri un issue includendo:

1. **Sistema Operativo**: Windows 10/11, Ubuntu 22.04, etc.
2. **Versione Qt**: `qmake --version`
3. **Versione GDAL**: `gdalinfo --version`
4. **File TIFF**: Output di `gdalinfo your_image.tif`
5. **Log Applicazione**: Output completo con debug abilitato
6. **Screenshot**: Errore visualizzato
7. **Tentativi**: Cosa hai già provato

---

## 📚 Risorse Utili

- **GDAL Documentation**: https://gdal.org/
- **GDAL Troubleshooting**: https://gdal.org/faq.html
- **GeoTIFF Spec**: https://www.ogc.org/standards/geotiff
- **Qt Image Provider**: https://doc.qt.io/qt-6/qquickimageprovider.html

---

**Versione**: 1.0  
**Ultima modifica**: Dicembre 2024
