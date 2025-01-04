#ifndef PLATFORM_H
#define PLATFORM_H

#include <QObject>
#include <QPointer>
#include <QQmlApplicationEngine>

class Platform : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isOnline READ getOnline WRITE setOnline NOTIFY onlineChanged FINAL)

public slots:

        // get application list from java and convert to QVariantList format that can be used directly in QML
        QVariantList applicationList();

        // launch application by package name
        void launchApplication(const QString &packageName);

        // open wallpaper picker menu
        void pickWallpaper();

        // return if system clock is in 24 hour format
        bool is24HourFormat();

public:

    // singleton, so we can propagate notifications from java
    static Platform &instance()
    {
        static Platform platform;
        return platform;
    }

    bool getOnline() const { return m_online; };
    void setOnline(bool online) { m_online = online; emit onlineChanged(); };

signals:
    // signal when packages have changed (installed/uninstalled)
    void packagesChanged();

    // signal when network connectivity state has changed
    void onlineChanged();

private:
    int m_online;

};

#endif // PLATFORM_H
