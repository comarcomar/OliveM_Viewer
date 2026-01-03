# OliveM_Viewer - Piano Integrazione .NET Hosting

## Stato Attuale: PULITO E FUNZIONANTE ✅

Codice base ripulito da tutti i tentativi precedenti.

### Struttura Source
- `main.cpp` - App Qt pulita, solo GDAL sistema
- `geotiffprocessor.cpp/h` - Elaborazione GeoTIFF
- `*.qml` - Interfaccia grafica
- `CMakeLists.txt` - Configurazione PULITA e SEMPLICE

### Funzionamento Corrente
✅ App compila senza errori  
✅ GDAL sistema funziona correttamente  
✅ DLL copiate automaticamente in build directory  
✅ Interfaccia grafica completa  

## Piano Integrazione OliveMatrixLibCore

### Approccio: .NET Hosting Nativo (Pulito)

**NO QLibrary** - Usa hosting nativo Microsoft  
**NO SetDllDirectory hacks** - .NET gestisce isolation automaticamente  
**NO path manipulation complessi** - Assembly loading context isolato  

### STEP 1: Aggiungere nethost

**Files da aggiungere**:
1. `nethost_loader.h` - Wrapper C++ per .NET hosting
2. `nethost_loader.cpp` - Implementazione
3. Headers minimal: `nethost.h`, `hostfxr.h`, `coreclr_delegates.h`

**CMakeLists aggiunte**:
```cmake
# Find nethost.lib
find_library(NETHOST_LIB nethost)
target_link_libraries(${PROJECT_NAME} PRIVATE ${NETHOST_LIB})

# Add nethost_loader to sources
set(PROJECT_SOURCES
    ...
    nethost_loader.cpp
    nethost_loader.h
)
```

### STEP 2: Wrapper C# Semplice

**OliveMatrixWrapper** (NUOVO progetto .NET 6):
```csharp
[UnmanagedCallersOnly]
public static unsafe int RunAnalysis(...)
{
    // Load OliveMatrixLibCore.dll dinamicamente
    Assembly.LoadFrom("OliveMatrixLibCore.dll");
    
    // Call method
    var instance = new OliveMatrixLib.OliveMatrixLibCore();
    return instance.RunAnalysis(...);
}
```

**NO static reference** - Caricamento dinamico a runtime  
**Assembly loading** - .NET gestisce dipendenze GDAL automaticamente  

### STEP 3: Deployment Isolato

**Struttura build finale**:
```
build/Debug/
├── OliveM_Viewer.exe
├── gdal*.dll (sistema - per Qt) ← Da C:\Sviluppo\gdal\bin
│
└── OliveMatrixWrapper/           ← ISOLATO
    ├── OliveMatrixWrapper.dll
    ├── OliveMatrixWrapper.runtimeconfig.json
    ├── OliveMatrixLibCore.dll
    └── [tutte deps GDAL OliveMatrix] ← .NET le gestisce
```

**Deployment CMake**:
```cmake
# Copy OliveMatrixWrapper build output
add_custom_command(
    COMMAND copy_directory 
        OliveMatrixWrapper/bin/Release/net6.0
        $<TARGET_FILE_DIR>/OliveMatrixWrapper
)
```

### STEP 4: Chiamata da C++

**In geotiffprocessor.cpp**:
```cpp
#include "nethost_loader.h"

bool GeoTiffProcessor::callRunAnalysis(...)
{
    NetHostLoader netHost;
    
    // Initialize .NET
    QString wrapperDll = appDir + "/OliveMatrixWrapper/OliveMatrixWrapper.dll";
    QString config = appDir + "/OliveMatrixWrapper/OliveMatrixWrapper.runtimeconfig.json";
    
    if (!netHost.initialize(wrapperDll, config))
        return false;
    
    // Get function pointer
    run_analysis_fn fn = netHost.getRunAnalysisFunction();
    
    // Call (native call, zero overhead)
    int result = fn(dsm, ndvi, shapefile, &fCov, &meanNdvi, denoise, threshold);
    
    netHost.cleanup();
    return (result == 0);
}
```

## Vantaggi Questo Approccio

✅ **PULITO**: Niente hack, solo API Microsoft ufficiali  
✅ **ISOLATO**: .NET gestisce AssemblyLoadContext automaticamente  
✅ **SEMPLICE**: 3 files C++, 1 progetto C#  
✅ **SICURO**: GDAL sistema e GDAL OliveMatrix completamente separate  
✅ **MANUTENIBILE**: Codice chiaro e standard  

## Test Plan

### Test 1: Build Base
```bash
cmake -B build
cmake --build build --config Debug
./build/Debug/OliveM_Viewer.exe
```
**Atteso**: App parte, carica GeoTIFF, GDAL sistema funziona ✅

### Test 2: Aggiungi nethost (solo link)
```bash
# Aggiungi nethost al CMakeLists
cmake -B build
cmake --build build --config Debug
```
**Atteso**: Compila senza errori, app parte normalmente ✅

### Test 3: Aggiungi wrapper C# (build separato)
```bash
cd OliveMatrixWrapper
dotnet build -c Release
```
**Atteso**: Wrapper compila, crea .dll + .runtimeconfig.json ✅

### Test 4: Integra chiamata
```bash
# Deploy wrapper in build
# Modifica geotiffprocessor.cpp
cmake --build build --config Debug
```
**Atteso**: Compila, app parte, RunAnalysis funziona ✅

## Differenza vs Tentativi Precedenti

| Aspetto | Prima (Confuso) | Ora (Pulito) |
|---------|-----------------|--------------|
| Approccio | QLibrary + SetDllDirectory | .NET hosting nativo |
| Path manipulation | PATH, SetDllDirectory, hack | .NET Assembly loading |
| GDAL isolation | Tentativi manuali falliti | AssemblyLoadContext automatico |
| Deployment | Copie DLL ovunque | Struttura chiara isolata |
| Codice | 500+ righe modifiche | <200 righe aggiunte |
| Manutenibilità | Incomprensibile | Chiaro e standard |

## Ready to Start?

Codice base **PULITO** e **FUNZIONANTE** ora disponibile in:
`/mnt/user-data/outputs/OliveM_Viewer_CLEAN/`

**Confermi di procedere con STEP 1** (aggiungere nethost)? 🎯
