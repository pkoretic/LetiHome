#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickView>
#include <QNetworkInformation>

#include "platform.h"
#include "keymapper.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    KeyMapper keyMapper;
    app.installEventFilter(&keyMapper);

    QQuickView::setDefaultAlphaBuffer(true);

    QQmlApplicationEngine engine;

    auto &platform = Platform::instance();

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, []() { QCoreApplication::exit(-1); },
                     Qt::QueuedConnection);

    // expose C++ classes to QML
    engine.rootContext()->setContextProperty("_platform", &platform);

    // initialize platform variables and listeners
    platform.init();

    // load main file
    engine.loadFromModule("LetiHomeModule", "Main");

    return app.exec();
}
