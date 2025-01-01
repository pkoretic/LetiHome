cmake_minimum_required(VERSION 3.16)

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
)

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
