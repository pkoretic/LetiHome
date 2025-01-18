#ifndef PLATFORM_H
#define PLATFORM_H

#include <QObject>
#include <QPointer>
#include <QQmlApplicationEngine>

class Platform : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isOnline READ getOnline WRITE setOnline NOTIFY onlineChanged FINAL)
    Q_PROPERTY(bool isTelevision READ getIsTelevision WRITE setIsTelevision NOTIFY isTelevisionChanged FINAL)

public slots:

        // get application list from java and convert to QVariantList format that can be used directly in QML
        QVariantList applicationList();

        // open application by package name
        void openApplication(const QString &packageName);

        // open wallpaper picker menu
        void pickWallpaper();

        // return if system clock is in 24 hour format
        bool is24HourFormat();

        // return if Android TV OS device
        bool isTelevision();

        // open android system settings
        void openSettings();

        // open application information dialog with open, install, remove etc options
        void openAppInfo(const QString &packageName);

        // open play store with leti home app
        void openLetiHomePage();

public:

    void init();

    // singleton, so we can propagate notifications from java
    static Platform &instance()
    {
        static Platform platform;
        return platform;
    }

    bool getOnline() const { return m_online; };
    void setOnline(bool online) { m_online = online; emit onlineChanged(); };

    bool getIsTelevision() const { return m_isTelevision; };
    void setIsTelevision(bool isTelevision) { m_isTelevision = isTelevision; emit isTelevisionChanged(); };

signals:
    // signal when packages have changed (installed/uninstalled/enabled/disabled)
    // action can be PACKAGE_CHANGED, PACKAGE_ADDED, PACKAGE_DELETED
    void packagesChanged(QString action, QString packageName, QString appName);

    // signal when network connectivity state has changed
    void onlineChanged();

    // signal when device is television
    void isTelevisionChanged();

private:
    int m_online;
    int m_isTelevision;

};

#endif // PLATFORM_H
