@echo off
REM Build script for OliveGeoTiffViewer using CMake and MSVC 2022

echo ==========================================
echo Building OliveGeoTiffViewer with CMake
echo Target: MSVC 2022 (Visual Studio 17)
echo ==========================================
echo.

REM Check if running in Visual Studio Developer Command Prompt
where cl >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: MSVC compiler not found in PATH
    echo.
    echo Please run this script from one of the following:
    echo - "x64 Native Tools Command Prompt for VS 2022"
    echo - "Developer Command Prompt for VS 2022"
    echo.
    echo Or manually run vcvarsall.bat:
    echo "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64
    echo.
    echo If using Professional or Enterprise, replace "Community" with your edition.
    echo.
    pause
    exit /b 1
)

REM Detect MSVC version
cl 2>&1 | findstr "19.3" >nul
if %ERRORLEVEL% EQU 0 (
    echo Found: MSVC 2022 (v143)
    set MSVC_VERSION=2022
) else (
    cl 2>&1 | findstr "19.2" >nul
    if %ERRORLEVEL% EQU 0 (
        echo Found: MSVC 2019 (v142) - will work but MSVC 2022 recommended
        set MSVC_VERSION=2019
    ) else (
        echo Warning: Unknown MSVC version detected
        set MSVC_VERSION=unknown
    )
)
echo.

REM Check for CMake
where cmake >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: cmake not found in PATH
    echo.
    echo Please install CMake from https://cmake.org/download/
    echo Or use: winget install Kitware.CMake
    echo.
    pause
    exit /b 1
)

cmake --version
echo.

REM Check for Qt6
set QT6_FOUND=0
set QT6_PATH=

REM Try to find Qt6 for MSVC 2022
for %%P in (
    "C:\Qt\6.8.0\msvc2022_64"
    "C:\Qt\6.7.0\msvc2022_64"
    "C:\Qt\6.6.0\msvc2022_64"
    "C:\Qt\6.5.3\msvc2022_64"
    "C:\Qt\6.5.0\msvc2022_64"
    "C:\Qt6\6.8.0\msvc2022_64"
    "C:\Qt6\6.7.0\msvc2022_64"
) do (
    if exist %%P (
        set QT6_PATH=%%~P
        set QT6_FOUND=1
        echo Found Qt6 for MSVC 2022: !QT6_PATH!
        goto :qt6_found
    )
)

REM Fallback: Try MSVC 2019 build (compatible with MSVC 2022)
if %QT6_FOUND% EQU 0 (
    echo Qt6 for MSVC 2022 not found, checking MSVC 2019 versions...
    for %%P in (
        "C:\Qt\6.8.0\msvc2019_64"
        "C:\Qt\6.7.0\msvc2019_64"
        "C:\Qt\6.6.0\msvc2019_64"
        "C:\Qt\6.5.3\msvc2019_64"
        "C:\Qt\6.5.0\msvc2019_64"
    ) do (
        if exist %%P (
            set QT6_PATH=%%~P
            set QT6_FOUND=1
            echo Found Qt6 for MSVC 2019 (compatible): !QT6_PATH!
            goto :qt6_found
        )
    )
)

:qt6_found
if %QT6_FOUND% EQU 0 (
    echo ERROR: Qt6 not found
    echo.
    echo Please install Qt6 from https://www.qt.io/download
    echo Install to one of these locations:
    echo   C:\Qt\6.8.0\msvc2022_64  (recommended)
    echo   C:\Qt\6.7.0\msvc2022_64
    echo   C:\Qt\6.6.0\msvc2022_64
    echo.
    echo Or manually specify with:
    echo   cmake -DCMAKE_PREFIX_PATH=C:\Path\To\Qt\6.x.x\msvc2022_64 ..
    echo.
    pause
    exit /b 1
)
echo.

REM Check for GDAL
if not exist "C:\OSGeo4W64\include\gdal.h" (
    echo WARNING: GDAL not found at C:\OSGeo4W64
    echo.
    echo Please install OSGeo4W from https://trac.osgeo.org/osgeo4w/
    echo The application will compile but may not link correctly without GDAL.
    echo.
    echo Press any key to continue anyway...
    pause >nul
) else (
    echo Found GDAL at C:\OSGeo4W64
)
echo.

REM Determine build directory
set BUILD_DIR=build_msvc_%MSVC_VERSION%

REM Clean previous build (optional)
if exist "%BUILD_DIR%" (
    echo Found existing build directory: %BUILD_DIR%
    echo.
    set /p CLEAN="Clean previous build? (y/N): "
    if /i "!CLEAN!"=="y" (
        echo Removing %BUILD_DIR%...
        rmdir /s /q "%BUILD_DIR%"
    )
)
echo.

REM Create build directory
if not exist "%BUILD_DIR%" (
    echo Creating build directory: %BUILD_DIR%
    mkdir "%BUILD_DIR%"
)

REM Configure with CMake
echo ==========================================
echo Configuring with CMake...
echo ==========================================
cd "%BUILD_DIR%"

cmake .. ^
    -G "Visual Studio 17 2022" ^
    -A x64 ^
    -DCMAKE_PREFIX_PATH="%QT6_PATH%" ^
    -DCMAKE_BUILD_TYPE=Release

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: CMake configuration failed
    cd ..
    pause
    exit /b 1
)
echo.

REM Build
echo ==========================================
echo Building project (Release)...
echo ==========================================
cmake --build . --config Release --parallel

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Build failed
    cd ..
    pause
    exit /b 1
)

cd ..
echo.

REM Success message
echo ==========================================
echo Build completed successfully!
echo ==========================================
echo.
echo Executable location:
echo   %BUILD_DIR%\Release\OliveGeoTiffViewer.exe
echo.
echo To run the application:
echo   1. Double-click: %BUILD_DIR%\Release\OliveGeoTiffViewer.exe
echo   2. Or use: %BUILD_DIR%\run.bat
echo.
echo Note: Qt6 DLLs and dependencies have been deployed to the Release folder.
echo.

REM Optionally open the build folder
set /p OPEN="Open build folder in Explorer? (y/N): "
if /i "%OPEN%"=="y" (
    explorer "%BUILD_DIR%\Release"
)

echo.
echo Press any key to exit...
pause >nul
