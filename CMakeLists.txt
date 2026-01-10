cmake_minimum_required(VERSION 3.16)
project(OliveM_Viewer VERSION 1.0.0 LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)
if(MSVC)
    add_compile_options(/W3 /MP /utf-8)
endif()

# Qt6
if(WIN32 AND NOT DEFINED QT6_DIR AND EXISTS "C:/Qt/6.10.1/msvc2022_64/lib/cmake/Qt6")
    set(QT6_DIR "C:/Qt/6.10.1/msvc2022_64/lib/cmake/Qt6")
endif()
find_package(Qt6 REQUIRED COMPONENTS Core Quick Qml QuickControls2 Quick3D)

# GDAL Sistema
if(WIN32)
    if(NOT DEFINED GDAL_ROOT AND EXISTS "C:/Sviluppo/gdal_gis")
        set(GDAL_ROOT "C:/Sviluppo/gdal_gis" CACHE PATH "GDAL root")
        set(GDAL_INCLUDE_DIR "${GDAL_ROOT}/include")
        set(GDAL_LIBRARY "${GDAL_ROOT}/lib/gdal_i.lib")
        set(GDAL_BIN_DIR "${GDAL_ROOT}/bin")
    endif()
endif()
if(NOT DEFINED GDAL_LIBRARY)
    find_package(GDAL REQUIRED)
endif()

# Sources
set(PROJECT_SOURCES main.cpp geotiffprocessor.cpp geotiffprocessor.h)
set(PROJECT_RESOURCES qml.qrc)

# Executable
if(WIN32)
    add_executable(${PROJECT_NAME} WIN32 ${PROJECT_SOURCES} ${PROJECT_RESOURCES} app.rc)
else()
    add_executable(${PROJECT_NAME} ${PROJECT_SOURCES} ${PROJECT_RESOURCES})
endif()

# Link
target_link_libraries(${PROJECT_NAME} PRIVATE Qt6::Core Qt6::Quick Qt6::Qml Qt6::QuickControls2 Qt6::Quick3D)
if(DEFINED GDAL_INCLUDE_DIR AND DEFINED GDAL_LIBRARY)
    target_include_directories(${PROJECT_NAME} PRIVATE ${GDAL_INCLUDE_DIR})
    target_link_libraries(${PROJECT_NAME} PRIVATE ${GDAL_LIBRARY})
else()
    target_link_libraries(${PROJECT_NAME} PRIVATE GDAL::GDAL)
endif()
target_include_directories(${PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

# Deployment
if(WIN32)
    get_target_property(QT6_QMAKE_EXECUTABLE Qt6::qmake IMPORTED_LOCATION)
    get_filename_component(QT6_BIN_DIR "${QT6_QMAKE_EXECUTABLE}" DIRECTORY)
    
    # Qt
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND "${QT6_BIN_DIR}/windeployqt6.exe" --qmldir "${CMAKE_SOURCE_DIR}" --no-translations "$<TARGET_FILE:${PROJECT_NAME}>"
        VERBATIM
    )
    
    # GDAL Sistema
    if(DEFINED GDAL_BIN_DIR AND EXISTS "${GDAL_BIN_DIR}")
        file(GLOB GDAL_SYSTEM_DLLS "${GDAL_BIN_DIR}/*.dll")
        foreach(DLL_FILE ${GDAL_SYSTEM_DLLS})
            add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_if_different "${DLL_FILE}" "$<TARGET_FILE_DIR:${PROJECT_NAME}>/"
            )
        endforeach()
    endif()
    
    # C++/CLI Bridge
    set(BRIDGE_DIR "${CMAKE_SOURCE_DIR}/OliveMatrixBridge/x64/Release")
    set(BRIDGE_DLL "${BRIDGE_DIR}/OliveMatrixBridge.dll")
    
    if(EXISTS "${BRIDGE_DLL}")
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different "${BRIDGE_DLL}" "$<TARGET_FILE_DIR:${PROJECT_NAME}>/"
        )
        
        # Copy runtimeconfig.json if exists
        if(EXISTS "${BRIDGE_DIR}/OliveMatrixBridge.runtimeconfig.json")
            add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_if_different 
                    "${BRIDGE_DIR}/OliveMatrixBridge.runtimeconfig.json" 
                    "$<TARGET_FILE_DIR:${PROJECT_NAME}>/OliveMatrixBridge.runtimeconfig.json"
                COMMENT "Copying Bridge runtimeconfig.json"
            )
        endif()
        
        # ijwhost.dll (correct path)
        set(IJWHOST_PATH "C:/Program Files/dotnet/packs/Microsoft.NETCore.App.Host.win-x64/6.0.36/runtimes/win-x64/native/ijwhost.dll")
        if(EXISTS "${IJWHOST_PATH}")
            add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_if_different "${IJWHOST_PATH}" "$<TARGET_FILE_DIR:${PROJECT_NAME}>/ijwhost.dll"
                COMMENT "Copying ijwhost.dll"
            )
        else()
            message(WARNING "ijwhost.dll not found at: ${IJWHOST_PATH}")
        endif()
    endif()
    
    # OliveMatrixLibCore → app directory root (NO subdirectory)
    # Deploy all content (DLLs, gdal/, dll/, runtimes/) directly to executable directory
    # This allows GdalConfiguration.cs to find gdal/ relative to OliveMatrixBridge.dll
    
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        set(OLIVEMATRIX_SOURCE "${CMAKE_SOURCE_DIR}/OliveMatrixLibCore/Debug")
    else()
        set(OLIVEMATRIX_SOURCE "${CMAKE_SOURCE_DIR}/OliveMatrixLibCore/Release")
    endif()
    
    # Fallback: try both if one doesn't exist
    if(NOT EXISTS "${OLIVEMATRIX_SOURCE}/OliveMatrixLibCore.dll")
        if(EXISTS "${CMAKE_SOURCE_DIR}/OliveMatrixLibCore/Release/OliveMatrixLibCore.dll")
            set(OLIVEMATRIX_SOURCE "${CMAKE_SOURCE_DIR}/OliveMatrixLibCore/Release")
            message(STATUS "Using Release build (Debug not found)")
        elseif(EXISTS "${CMAKE_SOURCE_DIR}/OliveMatrixLibCore/Debug/OliveMatrixLibCore.dll")
            set(OLIVEMATRIX_SOURCE "${CMAKE_SOURCE_DIR}/OliveMatrixLibCore/Debug")
            message(STATUS "Using Debug build (Release not found)")
        endif()
    endif()
    
    if(EXISTS "${OLIVEMATRIX_SOURCE}/OliveMatrixLibCore.dll")
        message(STATUS "Deploying OliveMatrixLibCore from: ${OLIVEMATRIX_SOURCE}")
        message(STATUS "  Build type: ${CMAKE_BUILD_TYPE}")
        message(STATUS "  Deploying to: $<TARGET_FILE_DIR:${PROJECT_NAME}>")
        message(STATUS "  Complete directory structure:")
        message(STATUS "    - OliveMatrixLibCore.dll + other DLLs")
        message(STATUS "    - dll/x64/")
        message(STATUS "    - gdal/data/")
        message(STATUS "    - gdal/share/")
        message(STATUS "    - gdal/x64/")
        message(STATUS "    - runtimes/")
        
        # Copy entire OliveMatrixLibCore directory content to app root
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory 
                "${OLIVEMATRIX_SOURCE}" 
                "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
            COMMENT "Deploying OliveMatrixLibCore to app root (${CMAKE_BUILD_TYPE})"
        )
        
        message(STATUS "")
        message(STATUS "Final deployment structure:")
        message(STATUS "  build/Debug/")
        message(STATUS "    ├── OliveM_Viewer.exe")
        message(STATUS "    ├── OliveMatrixBridge.dll")
        message(STATUS "    ├── OliveMatrixLibCore.dll")
        message(STATUS "    ├── [Qt DLLs]")
        message(STATUS "    ├── [GDAL system DLLs]")
        message(STATUS "    ├── dll/x64/        ← OliveMatrix dependencies")
        message(STATUS "    ├── gdal/           ← OliveMatrix GDAL")
        message(STATUS "    │   ├── data/")
        message(STATUS "    │   ├── share/")
        message(STATUS "    │   └── x64/")
        message(STATUS "    └── runtimes/       ← .NET runtimes")
    else()
        message(WARNING "OliveMatrixLibCore.dll not found in:")
        message(WARNING "  ${CMAKE_SOURCE_DIR}/OliveMatrixLibCore/Release/")
        message(WARNING "  ${CMAKE_SOURCE_DIR}/OliveMatrixLibCore/Debug/")
    endif()
endif()

install(TARGETS ${PROJECT_NAME} RUNTIME DESTINATION bin)
