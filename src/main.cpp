#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickView>
#include <QNetworkInformation>

#include "providers/platform.h"
#include "providers/iconprovider.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQuickView::setDefaultAlphaBuffer(true);

    QQmlApplicationEngine engine;

    auto &platform = Platform::instance();

    app.setApplicationDisplayName("LetiHome");
    app.setApplicationName("letihome");
    app.setOrganizationDomain("hr.envizia");

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, []() { QCoreApplication::exit(-1); },
                     Qt::QueuedConnection);

    // expose C++ classes to QML
    engine.addImageProvider(QLatin1String("icon"), new ImageProvider());
    engine.rootContext()->setContextProperty("_Platform", &platform);

    // initialize platform variables and listeners
    platform.init();

    // load main app module
    engine.loadFromModule("LetiHomeModule", "Main");

    return app.exec();
}
