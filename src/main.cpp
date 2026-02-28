#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickView>
#include <QNetworkInformation>

#include "providers/platform.h"
#include "providers/iconprovider.h"
#include "providers/bannerprovider.h"
#include "providers/keymapper.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    KeyMapper keyMapper;
    app.installEventFilter(&keyMapper);

    QQuickView::setDefaultAlphaBuffer(true);

    QQmlApplicationEngine engine;

    auto &platform = Platform::instance();

    app.setApplicationDisplayName("LetiHome");
    app.setApplicationName("letihomeplus");
    app.setOrganizationDomain("hr.envizia");

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, []() { QCoreApplication::exit(-1); },
                     Qt::QueuedConnection);

    // expose C++ classes to QML
    engine.addImageProvider("icon", new IconProvider());
    engine.addImageProvider("banner", new BannerProvider());
    engine.rootContext()->setContextProperty("_Platform", &platform);

    // initialize platform variables and listeners
    platform.init();

    // load main app module
    engine.loadFromModule("LetiHomePlusModule", "Main");

    return app.exec();
}
