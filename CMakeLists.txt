cmake_minimum_required(VERSION 3.16)

project(OliveM_Viewer VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# MSVC specific settings
if(MSVC)
    add_compile_options(/W3 /MP /utf-8)
endif()

# ============================================================================
# Qt6 Configuration
# ============================================================================
if(WIN32 AND NOT DEFINED QT6_DIR AND EXISTS "C:/Qt/6.10.1/msvc2022_64/lib/cmake/Qt6")
    set(QT6_DIR "C:/Qt/6.10.1/msvc2022_64/lib/cmake/Qt6")
endif()

find_package(Qt6 REQUIRED COMPONENTS Core Quick Qml QuickControls2 Quick3D)

# ============================================================================
# GDAL Configuration
# ============================================================================
if(WIN32)
    if(NOT DEFINED GDAL_DIR AND EXISTS "C:/Sviluppo/gdal/apps/gdal-dev")
        set(GDAL_DIR "C:/Sviluppo/gdal/apps/gdal-dev" CACHE PATH "GDAL directory")
        set(GDAL_INCLUDE_DIR "${GDAL_DIR}/include")
        set(GDAL_LIBRARY "${GDAL_DIR}/lib/gdal_i.lib")
    endif()
endif()

find_package(GDAL REQUIRED)

# ============================================================================
# .NET Hosting - Find nethost library
# ============================================================================
if(WIN32)
    set(NETHOST_SEARCH_PATHS
        "C:/Program Files/dotnet/packs/Microsoft.NETCore.App.Host.win-x64"
    )
    
    find_library(NETHOST_LIB
        NAMES nethost
        PATHS ${NETHOST_SEARCH_PATHS}
        PATH_SUFFIXES "*/runtimes/win-x64/native" "6.0.*/runtimes/win-x64/native"
        DOC "Path to nethost.lib"
    )
    
    if(NETHOST_LIB)
        message(STATUS "Found nethost.lib: ${NETHOST_LIB}")
    else()
        message(WARNING "nethost.lib not found - .NET hosting will not work")
        message(WARNING "Install .NET 6 SDK or set NETHOST_LIB manually:")
        message(WARNING "  cmake -DNETHOST_LIB=path/to/nethost.lib")
    endif()
endif()

# ============================================================================
# OliveMatrixWrapper (.NET 6 C# Project)
# ============================================================================
# Build the C# wrapper as a separate project before the main C++ executable
set(WRAPPER_PROJECT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/OliveMatrixWrapper")
set(WRAPPER_OUTPUT_DIR "${WRAPPER_PROJECT_DIR}/bin/Release/net6.0")

if(EXISTS "${WRAPPER_PROJECT_DIR}/OliveMatrixWrapper.csproj")
    message(STATUS "Found OliveMatrixWrapper C# project")
    
    # Add custom target to build C# wrapper
    add_custom_target(BuildOliveMatrixWrapper
        COMMAND dotnet build "${WRAPPER_PROJECT_DIR}/OliveMatrixWrapper.csproj" -c Release
        WORKING_DIRECTORY "${WRAPPER_PROJECT_DIR}"
        COMMENT "Building OliveMatrixWrapper (C#)..."
        VERBATIM
    )
    
    # Check if wrapper was built successfully
    if(EXISTS "${WRAPPER_OUTPUT_DIR}/OliveMatrixWrapper.dll")
        message(STATUS "  Wrapper output: ${WRAPPER_OUTPUT_DIR}")
    else()
        message(STATUS "  Wrapper not yet built - will build before main project")
    endif()
else()
    message(WARNING "OliveMatrixWrapper project not found at: ${WRAPPER_PROJECT_DIR}")
endif()

# ============================================================================
# Source Files
# ============================================================================
set(PROJECT_SOURCES
    main.cpp
    geotiffprocessor.cpp
    geotiffprocessor.h
    nethost_loader.cpp
    nethost_loader.h
    nethost.h
    hostfxr.h
    coreclr_delegates.h
)

set(PROJECT_RESOURCES qml.qrc)

# ============================================================================
# Executable
# ============================================================================
if(WIN32)
    add_executable(${PROJECT_NAME} WIN32 ${PROJECT_SOURCES} ${PROJECT_RESOURCES} app.rc)
else()
    add_executable(${PROJECT_NAME} ${PROJECT_SOURCES} ${PROJECT_RESOURCES})
endif()

# Make C++ executable depend on C# wrapper build
if(TARGET BuildOliveMatrixWrapper)
    add_dependencies(${PROJECT_NAME} BuildOliveMatrixWrapper)
    message(STATUS "OliveM_Viewer will build after OliveMatrixWrapper")
endif()

# ============================================================================
# Link Libraries
# ============================================================================
target_link_libraries(${PROJECT_NAME} PRIVATE
    Qt6::Core Qt6::Quick Qt6::Qml Qt6::QuickControls2 Qt6::Quick3D
)

# Link GDAL
if(WIN32 AND DEFINED GDAL_LIBRARY)
    target_include_directories(${PROJECT_NAME} PRIVATE ${GDAL_INCLUDE_DIR})
    target_link_libraries(${PROJECT_NAME} PRIVATE ${GDAL_LIBRARY})
else()
    target_link_libraries(${PROJECT_NAME} PRIVATE GDAL::GDAL)
endif()

# Link nethost for .NET hosting
if(NETHOST_LIB)
    target_link_libraries(${PROJECT_NAME} PRIVATE ${NETHOST_LIB})
    message(STATUS "Linking nethost library")
else()
    message(WARNING "nethost.lib not linked - .NET hosting will fail at runtime")
endif()

target_include_directories(${PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

# ============================================================================
# Windows Deployment
# ============================================================================
if(WIN32)
    # Qt deployment
    get_target_property(QT6_QMAKE_EXECUTABLE Qt6::qmake IMPORTED_LOCATION)
    get_filename_component(QT6_BIN_DIR "${QT6_QMAKE_EXECUTABLE}" DIRECTORY)
    
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND "${QT6_BIN_DIR}/windeployqt6.exe"
            --qmldir "${CMAKE_SOURCE_DIR}"
            --no-translations
            "$<TARGET_FILE:${PROJECT_NAME}>"
        COMMENT "Deploying Qt6 dependencies..."
        VERBATIM
    )
    
    # GDAL DLLs deployment
    # Try multiple locations for GDAL DLLs
    set(GDAL_DLL_SEARCH_PATHS
        "C:/Sviluppo/gdal/bin"
        "${GDAL_DIR}/bin"
        "${GDAL_DIR}/../../../bin"  # From apps/gdal-dev to root
    )
    
    foreach(SEARCH_PATH ${GDAL_DLL_SEARCH_PATHS})
        if(EXISTS "${SEARCH_PATH}" AND NOT GDAL_DLLS_COPIED)
            file(GLOB GDAL_DLLS "${SEARCH_PATH}/*.dll")
            if(GDAL_DLLS)
                message(STATUS "Copying GDAL DLLs from: ${SEARCH_PATH}")
                foreach(DLL_FILE ${GDAL_DLLS})
                    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
                        COMMAND ${CMAKE_COMMAND} -E copy_if_different
                            "${DLL_FILE}"
                            "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
                    )
                endforeach()
                set(GDAL_DLLS_COPIED TRUE)
            endif()
        endif()
    endforeach()
    
    if(NOT GDAL_DLLS_COPIED)
        message(WARNING "GDAL DLLs not found in: ${GDAL_DLL_SEARCH_PATHS}")
    endif()
    
    # ========================================================================
    # Deploy OliveMatrixWrapper
    # ========================================================================
    # Always try to copy - files will exist after wrapper build
    set(WRAPPER_DEPLOY_DIR "$<TARGET_FILE_DIR:${PROJECT_NAME}>/OliveMatrixWrapper")
    
    message(STATUS "Configuring OliveMatrixWrapper deployment")
    
    # Create wrapper directory
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory "${WRAPPER_DEPLOY_DIR}"
        COMMENT "Creating OliveMatrixWrapper directory..."
    )
    
    # Copy wrapper DLL (will exist after wrapper build)
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${WRAPPER_OUTPUT_DIR}/OliveMatrixWrapper.dll"
            "${WRAPPER_DEPLOY_DIR}/OliveMatrixWrapper.dll"
        COMMENT "Copying OliveMatrixWrapper.dll..."
    )
    
    # Copy runtime config (CRITICAL!)
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${WRAPPER_OUTPUT_DIR}/OliveMatrixWrapper.runtimeconfig.json"
            "${WRAPPER_DEPLOY_DIR}/OliveMatrixWrapper.runtimeconfig.json"
        COMMENT "Copying wrapper runtime config..."
    )
    
    # Copy deps.json
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${WRAPPER_OUTPUT_DIR}/OliveMatrixWrapper.deps.json"
            "${WRAPPER_DEPLOY_DIR}/OliveMatrixWrapper.deps.json"
        COMMENT "Copying wrapper deps..."
    )
    
    # Copy OliveMatrixLibCore.dll and dependencies
    set(OLIVEMATRIX_SEARCH_PATHS
        "${CMAKE_CURRENT_SOURCE_DIR}/OliveMatrixLibCore/Release"
        "${CMAKE_CURRENT_SOURCE_DIR}/OliveMatrixLibCore/Debug"
    )
    
    foreach(SEARCH_PATH ${OLIVEMATRIX_SEARCH_PATHS})
        if(EXISTS "${SEARCH_PATH}/OliveMatrixLibCore.dll" AND NOT OLIVEMATRIX_COPIED)
            message(STATUS "  OliveMatrixLibCore source: ${SEARCH_PATH}")
            
            # Copy main DLL
            add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_if_different
                    "${SEARCH_PATH}/OliveMatrixLibCore.dll"
                    "${WRAPPER_DEPLOY_DIR}/OliveMatrixLibCore.dll"
                COMMENT "Copying OliveMatrixLibCore.dll..."
            )
            
            # Copy ALL DLLs from gdal/x64
            if(EXISTS "${SEARCH_PATH}/gdal/x64")
                file(GLOB OLIVEMATRIX_GDAL_DLLS "${SEARCH_PATH}/gdal/x64/*.dll")
                message(STATUS "  Found ${CMAKE_MATCH_COUNT} GDAL DLLs in ${SEARCH_PATH}/gdal/x64")
                foreach(DLL_FILE ${OLIVEMATRIX_GDAL_DLLS})
                    get_filename_component(DLL_NAME "${DLL_FILE}" NAME)
                    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
                        COMMAND ${CMAKE_COMMAND} -E copy_if_different
                            "${DLL_FILE}"
                            "${WRAPPER_DEPLOY_DIR}/${DLL_NAME}"
                        COMMENT "Copying ${DLL_NAME} to wrapper..."
                    )
                endforeach()
            endif()
            
            set(OLIVEMATRIX_COPIED TRUE)
        endif()
    endforeach()
    
    if(NOT OLIVEMATRIX_COPIED)
        message(WARNING "OliveMatrixLibCore.dll not found - wrapper will fail at runtime!")
        message(WARNING "Expected location: OliveMatrixLibCore/Release/ or OliveMatrixLibCore/Debug/")
    endif()
endif()

# ============================================================================
# Installation
# ============================================================================
install(TARGETS ${PROJECT_NAME}
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)

# ============================================================================
# Configuration Summary
# ============================================================================
message(STATUS "")
message(STATUS "=== Configuration Summary ===")
message(STATUS "CMake: ${CMAKE_VERSION}")
message(STATUS "Compiler: ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}")
message(STATUS "Qt6: ${Qt6_VERSION}")
if(DEFINED GDAL_DIR)
    message(STATUS "GDAL: ${GDAL_DIR}")
    message(STATUS "GDAL Library: ${GDAL_LIBRARY}")
endif()
if(NETHOST_LIB)
    message(STATUS "nethost: ${NETHOST_LIB}")
endif()
message(STATUS "=============================")
message(STATUS "")
