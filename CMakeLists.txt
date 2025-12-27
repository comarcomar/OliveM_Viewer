cmake_minimum_required(VERSION 3.16)

project(OliveGeoTiffViewer VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# MSVC specific settings
if(MSVC)
    # Use static runtime for better portability
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
    
    # MSVC compiler flags
    add_compile_options(
        /W3                 # Warning level 3
        /MP                 # Multi-processor compilation
        /permissive-        # Standards conformance
        /Zc:__cplusplus     # Enable __cplusplus macro
        /utf-8              # UTF-8 source and execution
    )
    
    # MSVC 2022 specific optimizations
    if(MSVC_VERSION GREATER_EQUAL 1930)
        add_compile_options(
            /Zc:inline          # Remove unreferenced functions/data
            /Zc:preprocessor    # Enable conforming preprocessor (C11/C17)
        )
        message(STATUS "Detected MSVC 2022 or later (${MSVC_VERSION})")
    elseif(MSVC_VERSION GREATER_EQUAL 1920)
        message(STATUS "Detected MSVC 2019 (${MSVC_VERSION})")
    endif()
    
    # MSVC linker flags
    add_link_options(
        /MANIFEST:NO        # Don't generate manifest
        /INCREMENTAL:NO     # Disable incremental linking for release
    )
    
    # Release optimizations
    if(CMAKE_BUILD_TYPE STREQUAL "Release")
        add_compile_options(/O2 /Oi /Ot /GL)
        add_link_options(/LTCG /OPT:REF /OPT:ICF)
    endif()
endif()

# Set Qt installation path hints for MSVC 2019/2022
if(MSVC AND NOT DEFINED CMAKE_PREFIX_PATH)
    # Common Qt6 installation paths for MSVC 2019 and 2022
    set(QT6_POSSIBLE_PATHS
        # MSVC 2022 paths
        "C:/Qt/6.8.0/msvc2022_64"
        "C:/Qt/6.7.0/msvc2022_64"
        "C:/Qt/6.6.0/msvc2022_64"
        "C:/Qt/6.5.3/msvc2022_64"
        "C:/Qt/6.5.0/msvc2022_64"
        # MSVC 2019 paths (backward compatibility)
        "C:/Qt/6.8.0/msvc2019_64"
        "C:/Qt/6.7.0/msvc2019_64"
        "C:/Qt/6.6.0/msvc2019_64"
        "C:/Qt/6.5.3/msvc2019_64"
        "C:/Qt/6.5.0/msvc2019_64"
        # Alternative installation paths
        "C:/Qt6/6.8.0/msvc2022_64"
        "C:/Qt6/6.7.0/msvc2022_64"
        "C:/Qt6/6.6.0/msvc2022_64"
        "C:/Qt6/6.5.0/msvc2022_64"
    )
    
    foreach(QT_PATH ${QT6_POSSIBLE_PATHS})
        if(EXISTS "${QT_PATH}")
            set(CMAKE_PREFIX_PATH "${QT_PATH}")
            message(STATUS "Found Qt6 at: ${QT_PATH}")
            break()
        endif()
    endforeach()
    
    if(NOT CMAKE_PREFIX_PATH)
        message(WARNING "Qt6 not found in common locations. Please set CMAKE_PREFIX_PATH manually.")
        message(STATUS "Example for MSVC 2022: cmake -DCMAKE_PREFIX_PATH=C:/Qt/6.8.0/msvc2022_64 ..")
        message(STATUS "Example for MSVC 2019: cmake -DCMAKE_PREFIX_PATH=C:/Qt/6.5.0/msvc2019_64 ..")
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

# GDAL configuration for Windows/MSVC
if(WIN32)
    # Set GDAL paths for OSGeo4W64
    if(NOT DEFINED GDAL_DIR AND EXISTS "C:/OSGeo4W64")
        set(GDAL_DIR "C:/OSGeo4W64")
        set(GDAL_INCLUDE_DIR "${GDAL_DIR}/include")
        set(GDAL_LIBRARY "${GDAL_DIR}/lib/gdal_i.lib")
        
        message(STATUS "Using OSGeo4W64 GDAL")
        message(STATUS "GDAL Include: ${GDAL_INCLUDE_DIR}")
        message(STATUS "GDAL Library: ${GDAL_LIBRARY}")
    elseif(NOT DEFINED GDAL_DIR AND EXISTS "C:/OSGeo4W")
        # Fallback to 32-bit OSGeo4W
        set(GDAL_DIR "C:/OSGeo4W")
        set(GDAL_INCLUDE_DIR "${GDAL_DIR}/include")
        set(GDAL_LIBRARY "${GDAL_DIR}/lib/gdal_i.lib")
        
        message(STATUS "Using OSGeo4W (32-bit) GDAL")
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
    # Windows: Create GUI application (no console window)
    add_executable(${PROJECT_NAME} WIN32
        ${PROJECT_SOURCES}
        ${PROJECT_RESOURCES}
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
    # Manual linking for Windows
    target_include_directories(${PROJECT_NAME} PRIVATE ${GDAL_INCLUDE_DIR})
    target_link_libraries(${PROJECT_NAME} PRIVATE ${GDAL_LIBRARY})
else()
    # Standard CMake package linking
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
    
    message(STATUS "Qt6 bin directory: ${QT6_BIN_DIR}")
    
    # Deploy Qt dependencies using windeployqt6
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND "${QT6_BIN_DIR}/windeployqt6.exe"
            --qmldir "${CMAKE_SOURCE_DIR}"
            --no-translations
            --no-system-d3d-compiler
            --no-opengl-sw
            "$<TARGET_FILE:${PROJECT_NAME}>"
        COMMENT "Deploying Qt6 dependencies with windeployqt6..."
        VERBATIM
    )
    
    # Copy GDAL DLLs
    if(EXISTS "${GDAL_DIR}/bin")
        file(GLOB GDAL_DLLS "${GDAL_DIR}/bin/*.dll")
        foreach(DLL_FILE ${GDAL_DLLS})
            add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_if_different
                    "${DLL_FILE}"
                    "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
                COMMENT "Copying ${DLL_FILE}..."
            )
        endforeach()
    endif()
    
    # Copy OliveMatrixLib.dll if it exists
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/OliveMatrixLib.dll")
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${CMAKE_CURRENT_SOURCE_DIR}/OliveMatrixLib.dll"
                "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
            COMMENT "Copying OliveMatrixLib.dll..."
        )
    endif()
    
    # Create a batch file to run the application with proper PATH
    set(RUN_BAT_CONTENT "@echo off\nset PATH=%PATH%;${GDAL_DIR}\\bin\n\"$<TARGET_FILE:${PROJECT_NAME}>\"\n")
    file(GENERATE OUTPUT "${CMAKE_BINARY_DIR}/run_$<CONFIG>.bat" CONTENT "${RUN_BAT_CONTENT}")
    
    # Create a convenient run.bat that detects the build type
    file(WRITE "${CMAKE_BINARY_DIR}/run.bat" 
"@echo off
if exist \"${CMAKE_BINARY_DIR}/Release/${PROJECT_NAME}.exe\" (
    call \"${CMAKE_BINARY_DIR}/run_Release.bat\"
) else if exist \"${CMAKE_BINARY_DIR}/Debug/${PROJECT_NAME}.exe\" (
    call \"${CMAKE_BINARY_DIR}/run_Debug.bat\"
) else (
    echo Error: Executable not found. Please build the project first.
    pause
)
")
endif()

# Installation
install(TARGETS ${PROJECT_NAME}
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)

# Install Qt dependencies
if(WIN32)
    # Install Qt plugins and libraries
    install(DIRECTORY "$<TARGET_FILE_DIR:${PROJECT_NAME}>/"
        DESTINATION bin
        FILES_MATCHING
        PATTERN "*.dll"
        PATTERN "*.exe" EXCLUDE
    )
    
    # Install Qt plugins
    install(DIRECTORY "$<TARGET_FILE_DIR:${PROJECT_NAME}>/plugins"
        DESTINATION bin
        OPTIONAL
    )
    
    # Install QML modules
    install(DIRECTORY "$<TARGET_FILE_DIR:${PROJECT_NAME}>/QtQuick"
        DESTINATION bin
        OPTIONAL
    )
    
    install(DIRECTORY "$<TARGET_FILE_DIR:${PROJECT_NAME}>/QtQuick3D"
        DESTINATION bin
        OPTIONAL
    )
endif()

# CPack configuration for Windows installer
if(WIN32)
    set(CPACK_GENERATOR "NSIS;ZIP")
    set(CPACK_NSIS_ENABLE_UNINSTALL_BEFORE_INSTALL ON)
    set(CPACK_NSIS_MODIFY_PATH ON)
    set(CPACK_NSIS_DISPLAY_NAME "Olive GeoTIFF Viewer")
    set(CPACK_NSIS_PACKAGE_NAME "OliveGeoTiffViewer")
    set(CPACK_NSIS_CONTACT "support@olive-analysis.example.com")
    
    # Optional: Add icon if available
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/icon.ico")
        set(CPACK_NSIS_MUI_ICON "${CMAKE_CURRENT_SOURCE_DIR}/icon.ico")
        set(CPACK_NSIS_MUI_UNIICON "${CMAKE_CURRENT_SOURCE_DIR}/icon.ico")
    endif()
else()
    set(CPACK_GENERATOR "TGZ")
endif()

set(CPACK_PACKAGE_NAME "OliveGeoTiffViewer")
set(CPACK_PACKAGE_VENDOR "OliveAnalysis")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "GeoTIFF Analysis and Visualization Tool")
set(CPACK_PACKAGE_VERSION_MAJOR ${PROJECT_VERSION_MAJOR})
set(CPACK_PACKAGE_VERSION_MINOR ${PROJECT_VERSION_MINOR})
set(CPACK_PACKAGE_VERSION_PATCH ${PROJECT_VERSION_PATCH})
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE")
set(CPACK_RESOURCE_FILE_README "${CMAKE_CURRENT_SOURCE_DIR}/README.md")

include(CPack)

# Print configuration summary
message(STATUS "")
message(STATUS "========================================")
message(STATUS "  Configuration Summary")
message(STATUS "========================================")
message(STATUS "CMake Version: ${CMAKE_VERSION}")
message(STATUS "Generator: ${CMAKE_GENERATOR}")
message(STATUS "Compiler: ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}")
if(MSVC_VERSION)
    if(MSVC_VERSION GREATER_EQUAL 1930)
        message(STATUS "  - MSVC 2022 (v${MSVC_VERSION})")
    elseif(MSVC_VERSION GREATER_EQUAL 1920)
        message(STATUS "  - MSVC 2019 (v${MSVC_VERSION})")
    else()
        message(STATUS "  - MSVC (v${MSVC_VERSION})")
    endif()
endif()
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "C++ Standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "Qt6 Location: ${CMAKE_PREFIX_PATH}")
message(STATUS "Qt6 Version: ${Qt6_VERSION}")
if(WIN32 AND DEFINED GDAL_DIR)
    message(STATUS "GDAL Location: ${GDAL_DIR}")
    message(STATUS "GDAL Include: ${GDAL_INCLUDE_DIR}")
    message(STATUS "GDAL Library: ${GDAL_LIBRARY}")
endif()
message(STATUS "Output Directory: ${CMAKE_BINARY_DIR}")
message(STATUS "Install Prefix: ${CMAKE_INSTALL_PREFIX}")
message(STATUS "========================================")
message(STATUS "")
