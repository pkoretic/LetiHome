QT += qml quick quickcontrols2

CONFIG += c++14
CONFIG += qtquickcompiler

SOURCES += cpp/main.cpp
SOURCES += cpp/iconprovider.cpp
SOURCES += cpp/platform.cpp
HEADERS += cpp/platform.h
HEADERS += cpp/iconprovider.h

RESOURCES += qml/qml.qrc

# Default rules for deployment.
include(deployment.pri)

android {
    ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android
    ANDROID_VERSION_CODE = "8"
    ANDROID_VERSION_NAME = "1.3.0"

    DISTFILES += \
        android/AndroidManifest.xml \
        android/res/values/libs.xml \
        android/res/xml/qtprovider_paths.xml \
        android/src/hr/envizia/letihome/LetiHome.java \
        android/src/hr/envizia/letihome/PackagesChangedReceiver.java
}

CONFIG(debug, debug|release) {
    message("debug mode")
    DEFINES += DEBUG
} else
{
    message("release mode")
}
