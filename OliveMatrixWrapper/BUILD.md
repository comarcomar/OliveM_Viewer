# OliveMatrixWrapper - Build Instructions

## Struttura Progetto

```
OliveM_Viewer/
├── CMakeLists.txt                    ← Build principale
├── main.cpp
├── geotiffprocessor.cpp
├── *.qml
│
├── OliveMatrixWrapper/               ← Wrapper C# (NUOVO)
│   ├── OliveMatrixWrapper.csproj
│   └── NativeInterop.cs
│
└── OliveMatrixLibCore/               ← Source DLL (non in repo)
    ├── Release/
    │   ├── OliveMatrixLibCore.dll
    │   └── gdal/x64/*.dll
    └── Debug/
        ├── OliveMatrixLibCore.dll
        └── gdal/x64/*.dll
```

## Build Sequence

### 1. Wrapper C# (Automatico)

CMake esegue automaticamente:
```bash
dotnet build OliveMatrixWrapper/OliveMatrixWrapper.csproj -c Release
```

**Output**:
```
OliveMatrixWrapper/bin/Release/net6.0/
├── OliveMatrixWrapper.dll
├── OliveMatrixWrapper.runtimeconfig.json  ← Critico per .NET hosting!
└── OliveMatrixWrapper.deps.json
```

### 2. C++ Build (Dipende da #1)

```bash
cmake -B build
cmake --build build --config Debug
```

CMake:
1. ✅ Builda wrapper C# (se modificato)
2. ✅ Builda OliveM_Viewer.exe
3. ✅ Copia wrapper in `build/Debug/OliveMatrixWrapper/`
4. ✅ Copia OliveMatrixLibCore.dll da source
5. ✅ Copia GDAL dependencies da `OliveMatrixLibCore/[Release|Debug]/gdal/x64/`

## Deployment Finale

```
build/Debug/
├── OliveM_Viewer.exe
├── Qt6*.dll (windeployqt)
├── gdal*.dll (sistema - per Qt) ← Da C:\Sviluppo\gdal\bin
│
└── OliveMatrixWrapper/           ← ISOLATO
    ├── OliveMatrixWrapper.dll
    ├── OliveMatrixWrapper.runtimeconfig.json
    ├── OliveMatrixWrapper.deps.json
    ├── OliveMatrixLibCore.dll
    ├── gdal.dll              ← Versione OliveMatrix
    ├── spatialite.dll
    └── [tutte DLL da gdal/x64]
```

## Build in Qt Creator

### Prima Build

1. **Open Project**: Apri `CMakeLists.txt` in Qt Creator
2. **Configure**: Qt Creator esegue CMake automaticamente
3. **Build → Build All** (Ctrl+B)

**Output atteso**:
```
Building OliveMatrixWrapper (C#)...
Microsoft (R) Build Engine version ...
  OliveMatrixWrapper -> .../bin/Release/net6.0/OliveMatrixWrapper.dll
Build succeeded.

[ 33%] Building CXX object ...
[ 66%] Linking CXX executable OliveM_Viewer.exe
[100%] Built target OliveM_Viewer

Creating OliveMatrixWrapper directory...
Copying OliveMatrixWrapper.dll...
Copying wrapper runtime config...
Copying OliveMatrixLibCore.dll...
Copying gdal.dll...
Copying spatialite.dll...
...
```

### Build Successive

Qt Creator automaticamente:
- ✅ Rebuilda wrapper C# se modificato
- ✅ Rebuilda C++ se modificato
- ✅ Aggiorna deployment

## Verifica Build

```bash
# Check wrapper built
dir OliveMatrixWrapper\bin\Release\net6.0\OliveMatrixWrapper.dll

# Check deployment
dir build\Debug\OliveMatrixWrapper\OliveMatrixWrapper.dll
dir build\Debug\OliveMatrixWrapper\OliveMatrixLibCore.dll
dir build\Debug\OliveMatrixWrapper\gdal.dll
```

Tutti devono esistere! ✅

## Troubleshooting

### "dotnet not found"

**Problema**: .NET 6 SDK non installato o non in PATH

**Fix**:
```bash
# Verifica installazione
dotnet --version

# Deve mostrare: 6.0.x o superiore
```

Se non installato: https://dotnet.microsoft.com/download/dotnet/6.0

### "OliveMatrixWrapper.dll not built"

**Problema**: Build wrapper fallito

**Check**:
```bash
cd OliveMatrixWrapper
dotnet build -c Release
```

**Output deve essere**: `Build succeeded.`

### "OliveMatrixLibCore.dll not found"

**Problema**: Cartella source non trovata

**Check percorsi**:
```
OliveM_Viewer/OliveMatrixLibCore/Release/OliveMatrixLibCore.dll
OliveM_Viewer/OliveMatrixLibCore/Debug/OliveMatrixLibCore.dll
```

Uno dei due deve esistere!

### Wrapper non copiato in build

**Rebuild**:
```bash
# Qt Creator
Build → Clean All
Build → Run CMake
Build → Build All
```

## CMake Targets

```bash
# Build solo wrapper
cmake --build build --target BuildOliveMatrixWrapper

# Build solo C++
cmake --build build --target OliveM_Viewer

# Build tutto (automatico)
cmake --build build
```

## Vantaggi Integrazione CMake

✅ **Build automatico**: Wrapper rebuilda quando modificato  
✅ **Dipendenze**: C++ aspetta wrapper ready  
✅ **Deployment automatico**: Tutto copiato correttamente  
✅ **Qt Creator**: Funziona out-of-the-box  
✅ **CI/CD ready**: Script automatizzabili  

## Ready!

Il progetto è ora configurato per build automatico del wrapper C#.

**Prova build in Qt Creator!** 🎯
