cmake_minimum_required(VERSION 3.16)

project(OliveGeoTiffViewer VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)


# Find Qt packages
find_package(Qt6 REQUIRED COMPONENTS
    Core
    Quick
    Qml
    QuickControls2
    Quick3D
)

# Find GDAL
find_package(GDAL REQUIRED )

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
add_executable(${PROJECT_NAME}
    ${PROJECT_SOURCES}
    ${PROJECT_RESOURCES}
)

# Link Qt libraries
target_link_libraries(${PROJECT_NAME} PRIVATE
    Qt6::Core
    Qt6::Quick
    Qt6::Qml
    Qt6::QuickControls2
    Qt6::Quick3D
    GDAL::GDAL
)

# Include directories
target_include_directories(${PROJECT_NAME} PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
)

# Platform-specific settings
if(WIN32)
    # Windows: Copy GDAL DLLs to output directory
    if(EXISTS "${GDAL_LIBRARY_DIR}")
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${GDAL_LIBRARY_DIR}"
            $<TARGET_FILE_DIR:${PROJECT_NAME}>
        )
    endif()
    
    # Copy OliveMatrixLib.dll if it exists
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/OliveMatrixLib.dll")
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy
            "${CMAKE_CURRENT_SOURCE_DIR}/OliveMatrixLib.dll"
            $<TARGET_FILE_DIR:${PROJECT_NAME}>
        )
    endif()
endif()

# Installation
install(TARGETS ${PROJECT_NAME}
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)

# CPack configuration for packaging
set(CPACK_PACKAGE_NAME "OliveGeoTiffViewer")
set(CPACK_PACKAGE_VENDOR "OliveAnalysis")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "GeoTIFF Analysis and Visualization Tool")
set(CPACK_PACKAGE_VERSION_MAJOR ${PROJECT_VERSION_MAJOR})
set(CPACK_PACKAGE_VERSION_MINOR ${PROJECT_VERSION_MINOR})
set(CPACK_PACKAGE_VERSION_PATCH ${PROJECT_VERSION_PATCH})
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE")
set(CPACK_RESOURCE_FILE_README "${CMAKE_CURRENT_SOURCE_DIR}/README.md")

include(CPack)
