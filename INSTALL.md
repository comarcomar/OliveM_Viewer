# Guida all'Installazione - Olive GeoTIFF Viewer

Questa guida fornisce istruzioni dettagliate per l'installazione e la configurazione dell'applicazione su diversi sistemi operativi.

## Indice
1. [Requisiti di Sistema](#requisiti-di-sistema)
2. [Installazione Windows](#installazione-windows)
3. [Installazione Linux](#installazione-linux)
4. [Installazione macOS](#installazione-macos)
5. [Configurazione OliveMatrixLib](#configurazione-olivematrixlib)
6. [Risoluzione Problemi](#risoluzione-problemi)

---

## Requisiti di Sistema

### Hardware Minimo
- **CPU**: Dual-core 2.0 GHz
- **RAM**: 4 GB
- **GPU**: OpenGL 3.3+ supportato
- **Spazio disco**: 500 MB per l'applicazione + spazio per i dati GeoTIFF

### Hardware Raccomandato
- **CPU**: Quad-core 3.0 GHz o superiore
- **RAM**: 8 GB o superiore
- **GPU**: Dedicata con OpenGL 4.0+
- **SSD**: Per miglior performance con file grandi

---

## Installazione Windows

### Step 1: Installare Qt

#### Opzione A: Qt Online Installer (Raccomandato)
1. Scarica da: https://www.qt.io/download-qt-installer
2. Esegui l'installer
3. Durante l'installazione, seleziona:
   - Qt 6.5.0 o superiore (raccomandato 6.5+)
   - MSVC 2019 64-bit o MSVC 2022 64-bit
   - Qt Quick 3D
   - Qt Quick Controls
4. Completa l'installazione

#### Opzione B: Qt da Package Manager
```powershell
# Usando Chocolatey
choco install qt-sdk-windows
```

### Step 2: Installare GDAL

#### Metodo raccomandato: OSGeo4W
1. Scarica OSGeo4W installer da: https://trac.osgeo.org/osgeo4w/
2. Esegui `osgeo4w-setup.exe`
3. Seleziona "Advanced Install"
4. Scegli i pacchetti:
   - gdal
   - gdal-devel (headers e libs)
5. Installa in `C:\OSGeo4W64` (path predefinito)

#### Configurazione variabili d'ambiente
```powershell
# Aggiungi a PATH
setx PATH "%PATH%;C:\OSGeo4W64\bin"

# Variabili GDAL (opzionale)
setx GDAL_DATA "C:\OSGeo4W64\share\gdal"
setx GDAL_DRIVER_PATH "C:\OSGeo4W64\bin\gdalplugins"
```

### Step 3: Compilare l'Applicazione

#### Usando Qt Creator (Raccomandato per principianti)
1. Apri Qt Creator
2. File → Open File or Project
3. Seleziona `OliveGeoTiffViewer.pro`
4. Configura il progetto (seleziona kit MSVC)
5. Build → Build Project

#### Usando Command Line
```cmd
# Apri "Qt 5.15.2 (MSVC 2019 64-bit)" dal menu Start

cd percorso\a\OliveGeoTiffViewer
build_windows.bat
```

### Step 4: Deploy dell'Applicazione

```cmd
# Naviga nella directory dell'eseguibile
cd release  # o debug

# Usa windeployqt per copiare le DLL Qt necessarie
windeployqt OliveGeoTiffViewer.exe

# Copia le DLL GDAL
copy C:\OSGeo4W64\bin\*.dll .

# Copia OliveMatrixLib.dll se disponibile
copy ..\OliveMatrixLib.dll .
```

---

## Installazione Linux

### Step 1: Installare Dipendenze

#### Ubuntu / Debian
```bash
# Aggiorna il sistema
sudo apt-get update

# Ubuntu 22.04+ (Qt 6 disponibile)
sudo apt-get install -y \
    qt6-base-dev \
    qt6-declarative-dev \
    qt6-quick3d-dev \
    qml6-module-qtquick-controls \
    qml6-module-qtquick-dialogs \
    libqt6quick3d6

# Ubuntu 20.04 (richiede aggiungere repository o Qt installer)
# Usa Qt Online Installer da qt.io

# Installa GDAL
sudo apt-get install -y \
    gdal-bin \
    libgdal-dev

# Installa build tools
sudo apt-get install -y \
    build-essential \
    cmake
```

#### Fedora / RHEL / CentOS
```bash
# Installa Qt 6
sudo dnf install -y \
    qt6-qtbase-devel \
    qt6-qtdeclarative-devel \
    qt6-qtquickcontrols2-devel \
    qt6-qt3d-devel

# Installa GDAL
sudo dnf install -y \
    gdal \
    gdal-devel

# Build tools
sudo dnf groupinstall "Development Tools"
```

#### Arch Linux
```bash
# Installa Qt e GDAL
sudo pacman -S qt5-base qt5-declarative qt5-quickcontrols2 qt5-3d gdal

# Build tools
sudo pacman -S base-devel cmake
```

### Step 2: Compilare l'Applicazione

```bash
cd OliveGeoTiffViewer

# Metodo 1: qmake
./build_linux.sh

# Metodo 2: CMake
mkdir build
cd build
cmake ..
make -j$(nproc)
```

### Step 3: Installare (Opzionale)

```bash
# Installazione di sistema
sudo make install

# Oppure crea un AppImage
# (richiede linuxdeploy)
linuxdeploy --appdir AppDir --executable OliveGeoTiffViewer --output appimage
```

---

## Installazione macOS

### Step 1: Installare Homebrew
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Step 2: Installare Qt e GDAL
```bash
# Installa Qt 6
brew install qt@6

# Aggiungi Qt al PATH
echo 'export PATH="/opt/homebrew/opt/qt@6/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Installa GDAL
brew install gdal

# Installa pkg-config (per trovare GDAL)
brew install pkg-config
```

### Step 3: Compilare l'Applicazione

```bash
cd OliveGeoTiffViewer

# qmake
qmake OliveGeoTiffViewer.pro
make

# Oppure CMake
mkdir build && cd build
cmake ..
make
```

### Step 4: Creare App Bundle

```bash
# Usa macdeployqt per creare bundle
macdeployqt OliveGeoTiffViewer.app -qmldir=../

# L'app sarà in OliveGeoTiffViewer.app
```

---

## Configurazione OliveMatrixLib

### Windows

#### Compilare la DLL (se hai il codice sorgente)
```cmd
# Con MSVC
cl /LD /DOLIVEMATRIXLIB_EXPORTS OliveMatrixLib_example.cpp ^
   /I"C:\OSGeo4W64\include" ^
   /link /LIBPATH:"C:\OSGeo4W64\lib" gdal_i.lib

# Con MinGW
g++ -shared -DOLIVEMATRIXLIB_EXPORTS ^
    -o OliveMatrixLib.dll OliveMatrixLib_example.cpp ^
    -I"C:\OSGeo4W64\include" ^
    -L"C:\OSGeo4W64\lib" -lgdal_i
```

#### Posizionare la DLL
```cmd
# Copia nella directory dell'eseguibile
copy OliveMatrixLib.dll release\
# oppure
copy OliveMatrixLib.dll debug\
```

### Linux

#### Compilare la libreria condivisa
```bash
# Compila
g++ -shared -fPIC -DOLIVEMATRIXLIB_EXPORTS \
    -o libOliveMatrixLib.so OliveMatrixLib_example.cpp \
    $(gdal-config --cflags) $(gdal-config --libs)

# Rinomina per compatibilità
mv libOliveMatrixLib.so OliveMatrixLib.so
```

#### Installare la libreria
```bash
# Metodo 1: Nella directory dell'app
cp OliveMatrixLib.so ./

# Metodo 2: In directory di sistema
sudo cp OliveMatrixLib.so /usr/local/lib/
sudo ldconfig

# Metodo 3: Usa LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$(pwd)
```

### macOS

```bash
# Compila come dylib
g++ -dynamiclib -DOLIVEMATRIXLIB_EXPORTS \
    -o OliveMatrixLib.dylib OliveMatrixLib_example.cpp \
    $(gdal-config --cflags) $(gdal-config --libs)

# Posiziona nella stessa directory dell'app
cp OliveMatrixLib.dylib OliveGeoTiffViewer.app/Contents/MacOS/
```

---

## Risoluzione Problemi

### Windows

#### Problema: "Cannot find -lgdal_i"
**Soluzione**: Verifica che GDAL sia installato e che il path sia corretto nel file `.pro`:
```qmake
LIBS += -L"C:/OSGeo4W64/lib" -lgdal_i
```

#### Problema: L'app non si avvia - DLL mancanti
**Soluzione**: Usa Dependency Walker per identificare le DLL mancanti
```cmd
# Scarica da: http://www.dependencywalker.com/
# Oppure usa dumpbin
dumpbin /dependents OliveGeoTiffViewer.exe
```

#### Problema: "Failed to load OliveMatrixLib.dll"
**Soluzione**: 
1. Verifica che la DLL sia nella stessa directory dell'exe
2. Controlla le dipendenze della DLL
3. L'app funzionerà comunque in modalità fallback

### Linux

#### Problema: "error while loading shared libraries: libQt5Core.so.5"
**Soluzione**:
```bash
# Trova Qt
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH

# Oppure installa qt5-default
sudo apt-get install qt5-default
```

#### Problema: "cannot find -lgdal"
**Soluzione**:
```bash
# Verifica installazione GDAL
gdal-config --version

# Se non installato
sudo apt-get install libgdal-dev

# Verifica pkg-config
pkg-config --cflags --libs gdal
```

#### Problema: OpenGL non funziona
**Soluzione**:
```bash
# Installa driver Mesa
sudo apt-get install libgl1-mesa-dri

# Verifica supporto OpenGL
glxinfo | grep "OpenGL version"
```

### macOS

#### Problema: "dyld: Library not loaded"
**Soluzione**:
```bash
# Usa otool per vedere dipendenze
otool -L OliveGeoTiffViewer.app/Contents/MacOS/OliveGeoTiffViewer

# Usa install_name_tool per fixare path
install_name_tool -change /old/path/lib.dylib @executable_path/lib.dylib app
```

#### Problema: "Application is damaged"
**Soluzione**:
```bash
# Rimuovi quarantine attribute
xattr -cr OliveGeoTiffViewer.app
```

---

## Verifica dell'Installazione

### Test Base
```bash
# Linux/macOS
./OliveGeoTiffViewer --version

# Windows
OliveGeoTiffViewer.exe --version
```

### Test GDAL
```bash
# Verifica che GDAL sia accessibile
gdalinfo --version

# Test di apertura file
gdalinfo test.tif
```

### Test Qt
```bash
# Linux/macOS
qmake --version

# Windows (dalla Qt Command Prompt)
qmake -version
```

---

## Supporto

Per ulteriore assistenza:
1. Verifica il README.md per informazioni dettagliate
2. Controlla i log dell'applicazione
3. Apri un issue su GitHub con:
   - Versione OS
   - Versione Qt
   - Versione GDAL
   - Log completi dell'errore

---

**Ultima revisione**: 2024
**Versione applicazione**: 1.0.0
