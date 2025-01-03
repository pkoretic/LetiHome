cmake_minimum_required(VERSION 3.16)
include(FetchContent)

project(LetiHome VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(LetiHome
    cpp/main.cpp
    cpp/platform.cpp
    cpp/iconprovider.cpp
)

qt_add_qml_module(LetiHome
    URI LetiHomeModule
    VERSION 1.0
    QML_FILES
        qml/Main.qml
    SOURCES
        android/AndroidManifest.xml
        android/src/hr/envizia/letihome/LetiHome.java
        android/src/hr/envizia/letihome/PackagesChangedReceiver.java
)

if (ANDROID)
    FetchContent_Declare(
      android_openssl
      DOWNLOAD_EXTRACT_TIMESTAMP true
      URL      https://github.com/KDAB/android_openssl/archive/refs/heads/master.zip
    )
    FetchContent_MakeAvailable(android_openssl)
    include(${android_openssl_SOURCE_DIR}/android_openssl.cmake)

    add_android_openssl_libraries(LetiHome)
endif()


set_property(TARGET LetiHome APPEND PROPERTY QT_ANDROID_VERSION_CODE 8)
set_property(TARGET LetiHome APPEND PROPERTY QT_ANDROID_VERSION_NAME "1.3.0")

set_target_properties(LetiHome PROPERTIES
    QT_ANDROID_PACKAGE_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/android
)

target_link_libraries(LetiHome PRIVATE Qt6::Quick)

include(GNUInstallDirs)
install(TARGETS LetiHome
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
