cmake_minimum_required(VERSION 3.16)
include(FetchContent)

project(LetiHome VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Network Multimedia)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(LetiHome
    src/main.cpp
    src/providers/platform.cpp
    src/providers/iconprovider.cpp
    android/AndroidManifest.xml
    android/src/hr/envizia/letihome/LetiHome.java
    android/src/hr/envizia/letihome/PackagesChangedReceiver.java
)

qt_add_qml_module(LetiHome
    URI LetiHomeModule
    VERSION 1.0
    QML_FILES
        src/App.qml
        src/App.js
        src/About.qml
        src/Options.qml
        src/qmldir
        src/components/TopBar.qml
        src/components/AppsGrid.qml
        src/components/ColorLogo.js
        src/components/qmldir
        src/providers/PlatformProvider.qml
        src/providers/SettingsProvider.qml
        src/providers/qmldir
    RESOURCES
        assets/network-offline.svg
        assets/network-online.svg
)

set_target_properties(LetiHome PROPERTIES
    QT_ANDROID_PACKAGE_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/android
    QT_ANDROID_VERSION_CODE 16
    QT_ANDROID_VERSION_NAME "2.2.0"
    QT_ANDROID_MIN_SDK_VERSION 23
    QT_ANDROID_TARGET_SDK_VERSION 34
    QT_ANDROID_BUILD_ALL_ABIS OFF
    QT_ANDROID_ABIS "armeabi-v7a;arm64-v8a;x86;x86_64"
)

if (ANDROID)
    FetchContent_Declare(
      android_openssl
      DOWNLOAD_EXTRACT_TIMESTAMP true
      URL https://github.com/KDAB/android_openssl/archive/refs/heads/master.zip
    )
    FetchContent_MakeAvailable(android_openssl)
    include(${android_openssl_SOURCE_DIR}/android_openssl.cmake)
    add_android_openssl_libraries(LetiHome)
endif()

target_link_libraries(LetiHome PRIVATE Qt6::Quick Qt6::Network Qt6::Multimedia)

include(GNUInstallDirs)
install(TARGETS LetiHome
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
