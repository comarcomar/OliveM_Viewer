@echo off
REM Build script for OliveGeoTiffViewer on Windows

echo ======================================
echo Building OliveGeoTiffViewer
echo ======================================

REM Check if Qt is in PATH
where qmake >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: qmake not found in PATH
    echo Please add Qt bin directory to PATH, e.g.:
    echo set PATH=C:\Qt\5.15.2\msvc2019_64\bin;%%PATH%%
    exit /b 1
)

REM Check for GDAL
if not exist "C:\OSGeo4W64\include\gdal.h" (
    echo WARNING: GDAL not found at C:\OSGeo4W64
    echo Please install OSGeo4W or update the path in the .pro file
    echo Continuing anyway...
)

REM Clean previous build
echo.
echo Cleaning previous build...
if exist Makefile (
    nmake clean 2>nul
    del Makefile 2>nul
)
if exist Makefile.Debug del Makefile.Debug 2>nul
if exist Makefile.Release del Makefile.Release 2>nul

REM Run qmake
echo.
echo Running qmake...
qmake OliveGeoTiffViewer.pro
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: qmake failed
    exit /b 1
)

REM Build
echo.
echo Building project...
nmake
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Build failed
    exit /b 1
)

echo.
echo ======================================
echo Build completed successfully!
echo ======================================
echo.
echo Executable location:
if exist "release\OliveGeoTiffViewer.exe" (
    echo release\OliveGeoTiffViewer.exe
) else if exist "debug\OliveGeoTiffViewer.exe" (
    echo debug\OliveGeoTiffViewer.exe
) else (
    echo OliveGeoTiffViewer.exe
)

echo.
echo To run the application, make sure:
echo 1. Qt DLLs are in PATH or copied to exe directory
echo 2. GDAL DLLs are accessible
echo 3. OliveMatrixLib.dll is in the same directory (optional)
echo.

pause
