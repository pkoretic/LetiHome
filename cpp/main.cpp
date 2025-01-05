#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickView>
#include <QNetworkInformation>

#include "platform.h"
#include "iconprovider.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQuickView::setDefaultAlphaBuffer(true);

    QQmlApplicationEngine engine;

    auto &platform = Platform::instance();

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, []() { QCoreApplication::exit(-1); },
                     Qt::QueuedConnection);

    // expose C++ classes to QML
    engine.addImageProvider(QLatin1String("icon"), new ImageProvider());
    engine.rootContext()->setContextProperty("__platform", &platform);

    // load main file
    engine.loadFromModule("LetiHomeModule", "Main");

    // Listen to network reachability
    QNetworkInformation::loadDefaultBackend();
    auto networkInfo = QNetworkInformation::instance();
    platform.setOnline(networkInfo->reachability() == QNetworkInformation::Reachability::Online);
    QObject::connect(networkInfo, &QNetworkInformation::reachabilityChanged, [&platform](auto reachability) {
        platform.setOnline(reachability == QNetworkInformation::Reachability::Online);
    });

    platform.setIsTelevision(platform.isTelevision());

    return app.exec();
}
