cmake_minimum_required(VERSION 3.16)

project(OliveGeoTiffViewer VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# MSVC specific settings
if(MSVC)
    add_compile_options(
        /W3                 # Warning level 3
        /MP                 # Multi-processor compilation
        /utf-8              # UTF-8 source and execution
    )
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
    # Set GDAL paths for OSGeo4W64
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
    
    # Copy OliveMatrixLib.dll if it exists
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/OliveMatrixLib.dll")
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${CMAKE_CURRENT_SOURCE_DIR}/OliveMatrixLib.dll"
                "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
        )
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
