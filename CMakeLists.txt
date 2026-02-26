cmake_minimum_required(VERSION 3.16)
include(FetchContent)

project(LetiHomePlus VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Network)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(LetiHomePlus
    src/main.cpp
    src/providers/platform.cpp
    src/providers/platform.h
    src/providers/iconprovider.cpp
    src/providers/iconprovider.h
    src/providers/bannerprovider.cpp
    src/providers/bannerprovider.h
    android/AndroidManifest.xml
    android/build.gradle
    android/gradle.properties
    android/src/hr/envizia/letihomeplus/LetiHomePlus.java
    android/src/hr/envizia/letihomeplus/PackagesChangedReceiver.java
)

qt_add_qml_module(LetiHomePlus
    URI LetiHomePlusModule
    VERSION 1.0
    QML_FILES
        src/Main.qml
        src/Home.qml
        src/About.qml
        src/Options.qml
        src/components/TopBar.qml
        src/components/AppsGrid.qml
        src/components/AppsList.qml
        src/components/ColorLogo.js
        src/components/IconBanner.qml
        src/providers/PlatformProvider.qml
        src/providers/SettingsProvider.qml
        src/providers/AppsProvider.qml
        src/providers/NavigationProvider.qml
    RESOURCES
        src/qmldir
        src/components/qmldir
        src/providers/qmldir
        assets/network-offline.svg
        assets/ethernet-online.svg
        assets/wifi-online.svg
        assets/settings.svg
        assets/tvinput.svg
)

# Version: override via -DQT_ANDROID_VERSION_NAME=X.Y.Z -DQT_ANDROID_VERSION_CODE=N
# Defaults are dev placeholders; CI injects real values from the git tag.
if(NOT DEFINED QT_ANDROID_VERSION_NAME)
    set(QT_ANDROID_VERSION_NAME "0.0.0")
endif()
if(NOT DEFINED QT_ANDROID_VERSION_CODE)
    set(QT_ANDROID_VERSION_CODE 1)
endif()

set_target_properties(LetiHomePlus PROPERTIES
    QT_ANDROID_PACKAGE_NAME "hr.envizia.letihomeplus"
    QT_ANDROID_PACKAGE_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/android
    QT_ANDROID_VERSION_CODE ${QT_ANDROID_VERSION_CODE}
    QT_ANDROID_VERSION_NAME "${QT_ANDROID_VERSION_NAME}"
    QT_ANDROID_MIN_SDK_VERSION 23
    QT_ANDROID_COMPILE_SDK_VERSION "android-35"
    QT_ANDROID_SDK_BUILD_TOOLS_REVISION "35.0.1"
    QT_ANDROID_TARGET_SDK_VERSION 35
    QT_ANDROID_BUILD_ALL_ABIS ${QT_ANDROID_BUILD_ALL_ABIS}
    QT_ANDROID_ABIS "${QT_ANDROID_ABIS}"
)

if (ANDROID)
    FetchContent_Declare(
      android_openssl
      DOWNLOAD_EXTRACT_TIMESTAMP true
      URL https://github.com/KDAB/android_openssl/archive/refs/heads/master.zip
    )
    FetchContent_MakeAvailable(android_openssl)
    include(${android_openssl_SOURCE_DIR}/android_openssl.cmake)
    add_android_openssl_libraries(LetiHomePlus)
endif()

target_link_libraries(LetiHomePlus PRIVATE Qt6::Quick Qt6::Network)

include(GNUInstallDirs)
install(TARGETS LetiHomePlus
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
