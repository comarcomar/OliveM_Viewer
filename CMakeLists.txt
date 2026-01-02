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
# Source Files
# ============================================================================
set(PROJECT_SOURCES
    main.cpp
    geotiffprocessor.cpp
    geotiffprocessor.h
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
message(STATUS "=============================")
message(STATUS "")
