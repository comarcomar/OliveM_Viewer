#!/bin/bash

# Build script for OliveGeoTiffViewer on Linux

echo "======================================"
echo "Building OliveGeoTiffViewer"
echo "======================================"

# Check if qmake is available
if ! command -v qmake &> /dev/null; then
    echo "ERROR: qmake not found in PATH"
    echo "Please install Qt development packages, e.g.:"
    echo "  Ubuntu/Debian: sudo apt-get install qt5-qmake qtdeclarative5-dev"
    echo "  Fedora: sudo dnf install qt5-qtbase-devel qt5-qtdeclarative-devel"
    exit 1
fi

# Check for GDAL
if ! pkg-config --exists gdal; then
    echo "WARNING: GDAL not found via pkg-config"
    echo "Please install GDAL development packages, e.g.:"
    echo "  Ubuntu/Debian: sudo apt-get install libgdal-dev"
    echo "  Fedora: sudo dnf install gdal-devel"
    echo "Continuing anyway..."
fi

# Clean previous build
echo ""
echo "Cleaning previous build..."
if [ -f Makefile ]; then
    make clean 2>/dev/null
    rm -f Makefile
fi

# Run qmake
echo ""
echo "Running qmake..."
qmake OliveGeoTiffViewer.pro
if [ $? -ne 0 ]; then
    echo "ERROR: qmake failed"
    exit 1
fi

# Build
echo ""
echo "Building project..."
make -j$(nproc)
if [ $? -ne 0 ]; then
    echo "ERROR: Build failed"
    exit 1
fi

echo ""
echo "======================================"
echo "Build completed successfully!"
echo "======================================"
echo ""
echo "Executable: ./OliveGeoTiffViewer"
echo ""
echo "To run the application:"
echo "  ./OliveGeoTiffViewer"
echo ""
echo "Make sure OliveMatrixLib.so is in the same directory or in LD_LIBRARY_PATH (optional)"
echo ""
