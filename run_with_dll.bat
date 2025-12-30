@echo off
REM Helper script to run OliveGeoTiffViewer with OliveMatrixLibCore.dll in PATH
REM Usage: run_with_dll.bat [Release|Debug]

set BUILD_TYPE=%1
if "%BUILD_TYPE%"=="" set BUILD_TYPE=Release

REM Set path to OliveMatrixLibCore
set OLIVEMATRIX_DIR=%~dp0OliveMatrixLibCore\%BUILD_TYPE%\net6.0
set GDAL_DIR=%OLIVEMATRIX_DIR%\gdal\x64

echo Setting up environment for OliveGeoTiffViewer
echo OliveMatrixLibCore: %OLIVEMATRIX_DIR%
echo GDAL dependencies: %GDAL_DIR%

REM Add to PATH
set PATH=%OLIVEMATRIX_DIR%;%GDAL_DIR%;%PATH%

REM Run the application
echo.
echo Starting OliveGeoTiffViewer...
rem OliveGeoTiffViewer.exe

pause
