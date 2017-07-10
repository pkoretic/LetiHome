QT += qml quick quickcontrols2

CONFIG += c++14

SOURCES += cpp/main.cpp
SOURCES += cpp/iconprovider.cpp
SOURCES += cpp/platform.cpp
HEADERS += cpp/platform.h
HEADERS += cpp/iconprovider.h

RESOURCES += qml/qml.qrc

# Default rules for deployment.
include(deployment.pri)

android-g++ {
    QT += androidextras
    ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android

    DISTFILES += \
        android/AndroidManifest.xml \
        android/res/values/libs.xml \
        android/src/com/qaap/letihome/LetiHome.java \
        android/src/com/qaap/letihome/PackagesChangedReceiver.java
}

CONFIG(debug, debug|release) {
    message("debug mode")
    DEFINES += DEBUG
} else
{
    message("release mode")
}
