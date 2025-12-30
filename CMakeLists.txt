cmake_minimum_required(VERSION 3.16)

project(OliveM_Viewer VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# OliveMatrixLibCore.dll path configuration
# Auto-detect if present in source directory
set(OLIVEMATRIX_PATH "" CACHE PATH "Path to OliveMatrixLibCore.dll directory (e.g., OliveMatrixLibCore/Release/net6.0)")

if(NOT OLIVEMATRIX_PATH OR NOT EXISTS "${OLIVEMATRIX_PATH}")
    # Try to auto-detect in source directory
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/OliveMatrixLibCore/Release/net6.0")
        set(OLIVEMATRIX_PATH "${CMAKE_CURRENT_SOURCE_DIR}/OliveMatrixLibCore/Release/net6.0")
        message(STATUS "Auto-detected OliveMatrixLibCore (Release): ${OLIVEMATRIX_PATH}")
    elseif(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/OliveMatrixLibCore/Debug/net6.0")
        set(OLIVEMATRIX_PATH "${CMAKE_CURRENT_SOURCE_DIR}/OliveMatrixLibCore/Debug/net6.0")
        message(STATUS "Auto-detected OliveMatrixLibCore (Debug): ${OLIVEMATRIX_PATH}")
    else()
        message(STATUS "OliveMatrixLibCore not found in source directory")
        message(STATUS "Expected: ${CMAKE_CURRENT_SOURCE_DIR}/OliveMatrixLibCore/[Release|Debug]/net6.0")
        message(STATUS "The DLL will be loaded from system PATH or executable directory")
    endif()
endif()

if(OLIVEMATRIX_PATH AND EXISTS "${OLIVEMATRIX_PATH}")
    message(STATUS "OliveMatrixLibCore path: ${OLIVEMATRIX_PATH}")
endif()

# MSVC specific settings
if(MSVC)
    add_compile_options(
        /W3                 # Warning level 3
        /MP                 # Multi-processor compilation
        /utf-8              # UTF-8 source and execution
    )
endif()

# QT6 configuration for Windows
if(WIN32)
    # Set GDAL paths
    if(NOT DEFINED QT6_DIR AND EXISTS "C:/Qt/6.10.1/msvc2022_64/lib/cmake/Qt6")
        set(QT6_DIR "C:/Qt/6.10.1/msvc2022_64/lib/cmake/Qt6")
    endif()
endif()

# Find Qt packages
find_package(Qt6 REQUIRED COMPONENTS
    Core
    Quick
    Qml
    QuickControls2
    Quick3D
)

# GDAL configuration for Windows
if(WIN32)
    # Set GDAL paths
    if(NOT DEFINED GDAL_DIR AND EXISTS "C:/Sviluppo/gdal/apps/gdal-dev")
        set(GDAL_DIR "C:/Sviluppo/gdal/apps/gdal-dev")
        set(GDAL_INCLUDE_DIR "${GDAL_DIR}/include")
        set(GDAL_LIBRARY "${GDAL_DIR}/lib/gdal_i.lib")
        
        message(STATUS "Using GDAL")
        message(STATUS "GDAL Include: ${GDAL_INCLUDE_DIR}")
        message(STATUS "GDAL Library: ${GDAL_LIBRARY}")
    endif()
endif()

# Find GDAL
find_package(GDAL REQUIRED)

# Source files
set(PROJECT_SOURCES
    main.cpp
    geotiffprocessor.cpp
    geotiffprocessor.h
)

# QML and resource files
set(PROJECT_RESOURCES
    qml.qrc
)

# Create executable
if(WIN32)
    add_executable(${PROJECT_NAME} WIN32
        ${PROJECT_SOURCES}
        ${PROJECT_RESOURCES}
        app.rc
    )
else()
    add_executable(${PROJECT_NAME}
        ${PROJECT_SOURCES}
        ${PROJECT_RESOURCES}
    )
endif()

# Link Qt libraries
target_link_libraries(${PROJECT_NAME} PRIVATE
    Qt6::Core
    Qt6::Quick
    Qt6::Qml
    Qt6::QuickControls2
    Qt6::Quick3D
)

# Link GDAL
if(WIN32 AND DEFINED GDAL_LIBRARY)
    target_include_directories(${PROJECT_NAME} PRIVATE ${GDAL_INCLUDE_DIR})
    target_link_libraries(${PROJECT_NAME} PRIVATE ${GDAL_LIBRARY})
else()
    target_link_libraries(${PROJECT_NAME} PRIVATE GDAL::GDAL)
endif()

# Include directories
target_include_directories(${PROJECT_NAME} PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
)

# Windows-specific post-build steps
if(WIN32)
    # Get Qt6 bin directory
    get_target_property(QT6_QMAKE_EXECUTABLE Qt6::qmake IMPORTED_LOCATION)
    get_filename_component(QT6_BIN_DIR "${QT6_QMAKE_EXECUTABLE}" DIRECTORY)
    
    # Deploy Qt dependencies
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND "${QT6_BIN_DIR}/windeployqt6.exe"
            --qmldir "${CMAKE_SOURCE_DIR}"
            --no-translations
            "$<TARGET_FILE:${PROJECT_NAME}>"
        COMMENT "Deploying Qt6 dependencies..."
        VERBATIM
    )
    
    # Copy GDAL DLLs if found
    if(EXISTS "${GDAL_DIR}/bin")
        file(GLOB GDAL_DLLS "${GDAL_DIR}/bin/*.dll")
        foreach(DLL_FILE ${GDAL_DLLS})
            add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_if_different
                    "${DLL_FILE}"
                    "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
            )
        endforeach()
    endif()
    
    # Copy OliveMatrixLibCore.dll and dependencies if path is specified
    if(OLIVEMATRIX_PATH AND EXISTS "${OLIVEMATRIX_PATH}")
        message(STATUS "Copying OliveMatrixLibCore from: ${OLIVEMATRIX_PATH}")
        
        # List of DLLs that MUST be excluded (version conflicts with system)
        # These are native libraries that must match the compile-time versions
        set(EXCLUDED_DLLS
            "gdal"           # GDAL library
            "geos"           # GEOS library  
            "proj"           # PROJ library
            "sqlite3"        # SQLite
            "spatialite"     # SpatiaLite
            "openjp2"        # OpenJPEG (opj_* functions)
            "tiff"           # LibTIFF
            "geotiff"        # GeoTIFF
            "jpeg"           # JPEG
            "png"            # PNG
            "zlib"           # ZLib
            "curl"           # cURL
            "ssl"            # OpenSSL
            "crypto"         # OpenSSL crypto
            "expat"          # Expat XML
            "xml2"           # libxml2
            "iconv"          # iconv
            "hdf5"           # HDF5
            "netcdf"         # NetCDF
            "kea"            # KEA
            "webp"           # WebP
        )
        
        # Get all DLLs from OliveMatrixLibCore directory
        file(GLOB OLIVEMATRIX_ALL_DLLS "${OLIVEMATRIX_PATH}/*.dll")
        
        # Filter out excluded DLLs
        set(OLIVEMATRIX_DLLS "")
        foreach(DLL_FILE ${OLIVEMATRIX_ALL_DLLS})
            get_filename_component(DLL_NAME "${DLL_FILE}" NAME_WE)
            
            set(IS_EXCLUDED FALSE)
            foreach(EXCLUDED ${EXCLUDED_DLLS})
                string(TOLOWER "${DLL_NAME}" DLL_NAME_LOWER)
                string(TOLOWER "${EXCLUDED}" EXCLUDED_LOWER)
                if("${DLL_NAME_LOWER}" MATCHES "^${EXCLUDED_LOWER}")
                    set(IS_EXCLUDED TRUE)
                    message(STATUS "  Excluding (version conflict): ${DLL_NAME}.dll")
                    break()
                endif()
            endforeach()
            
            if(NOT IS_EXCLUDED)
                list(APPEND OLIVEMATRIX_DLLS "${DLL_FILE}")
            endif()
        endforeach()
        
        # Copy only .NET and non-conflicting DLLs
        foreach(DLL_FILE ${OLIVEMATRIX_DLLS})
            get_filename_component(DLL_NAME "${DLL_FILE}" NAME)
            add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_if_different
                    "${DLL_FILE}"
                    "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
                COMMENT "  Copying: ${DLL_NAME}"
            )
        endforeach()
        
        # Copy JSON config files
        file(GLOB OLIVEMATRIX_JSON "${OLIVEMATRIX_PATH}/*.json")
        foreach(JSON_FILE ${OLIVEMATRIX_JSON})
            add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_if_different
                    "${JSON_FILE}"
                    "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
            )
        endforeach()
        
        # NOTE: All native libraries (GDAL, OpenJPEG, etc.) come from system GDAL
        # This prevents version conflicts between compile-time and runtime
        message(STATUS "Using system native libraries (GDAL, OpenJPEG, etc.) to avoid conflicts")
        
        # Add to PATH at runtime (Visual Studio)
        set_target_properties(${PROJECT_NAME} PROPERTIES
            VS_DEBUGGER_ENVIRONMENT "PATH=$<TARGET_FILE_DIR:${PROJECT_NAME}>;%PATH%"
        )
    else()
        message(STATUS "OliveMatrixLibCore not copied - ensure DLL is in system PATH")
        message(STATUS "To copy DLL automatically, set: -DOLIVEMATRIX_PATH=path/to/OliveMatrixLibCore/Release/net6.0")
    endif()
endif()

# Installation
install(TARGETS ${PROJECT_NAME}
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)

# Print configuration summary
message(STATUS "")
message(STATUS "========================================")
message(STATUS "  Configuration Summary")
message(STATUS "========================================")
message(STATUS "CMake Version: ${CMAKE_VERSION}")
message(STATUS "Compiler: ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}")
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Qt6 Version: ${Qt6_VERSION}")
if(WIN32 AND DEFINED GDAL_DIR)
    message(STATUS "GDAL Location: ${GDAL_DIR}")
endif()
message(STATUS "========================================")
message(STATUS "")
