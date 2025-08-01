#include <QCoreApplication>
#include <QNetworkInformation>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>

#include "platform.h"


void Platform::init()
{
    // Listen to network reachability
    QNetworkInformation::loadDefaultBackend();
    auto networkInfo = QNetworkInformation::instance();
    this->setOnline(networkInfo->reachability() == QNetworkInformation::Reachability::Online);
    this->setIsEthernet(networkInfo->transportMedium() == QNetworkInformation::TransportMedium::Ethernet);

    QObject::connect(networkInfo, &QNetworkInformation::reachabilityChanged, this, [this](auto reachability ) {
        this->setOnline(reachability == QNetworkInformation::Reachability::Online);
    });

    QObject::connect(networkInfo, &QNetworkInformation::transportMediumChanged, this, [this](auto transportMedium ) {
        this->setIsEthernet(transportMedium == QNetworkInformation::TransportMedium::Ethernet);
    });

    this->setIsTelevision(this->isTelevision());
}

// maybe we will support some other platform in the future
#ifdef Q_OS_ANDROID
#include <QJniObject>

/*
 these are JNI functions called from java
*/

void onPackagesChanged(JNIEnv /* *env */, jobject /* self */)
{
    QMetaObject::invokeMethod(&Platform::instance(), "packagesChanged", Qt::QueuedConnection);
}

// called on JNI LOAD, register native methods to corresponding classes
jint JNICALL JNI_OnLoad(JavaVM* vm, void*)
{
    JNIEnv* env;

    if (vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) != JNI_OK)
        return JNI_ERR;

    // get main receiver class
    QJniObject receiver = QJniObject("hr/envizia/letihome/PackagesChangedReceiver");
    jclass receiverClass = env->GetObjectClass(receiver.object<jobject>());
    if (!receiverClass)
    {
        // this should never happen
        qWarning() << "receiver class found!";
        return JNI_ERR;
    }

    // register native methods
    JNINativeMethod packagesMethods[] {{ "onPackagesChanged", "()V", reinterpret_cast<void *>(onPackagesChanged) }};
    env->RegisterNatives(receiverClass, packagesMethods, sizeof(packagesMethods) / sizeof(packagesMethods[0]));
    env->DeleteLocalRef(receiverClass);

    return JNI_VERSION_1_6;
}
#endif

// get application list from java and convert to QVariantList format that can be used directly in QML
QVariantList Platform::applicationList()
{
    QVariantList appList;

#ifdef Q_OS_ANDROID

    QJniObject activity = QNativeInterface::QAndroidApplication::context();
    QJniObject jsonApplications = activity.callObjectMethod("applicationList", "()Ljava/lang/String;");
    QString jsonString = jsonApplications.toString();

    QJsonDocument jsonDoc = QJsonDocument::fromJson(jsonString.toUtf8());
    if (jsonDoc.isObject()) {
        QJsonObject jsonObj = jsonDoc.object();
        for (auto it = jsonObj.begin(); it != jsonObj.end(); ++it) {
            QString packageName = it.key();
            QJsonObject appObject = it.value().toObject();
            QVariantMap data;
            data["packageName"] = packageName;
            data["applicationName"] = appObject.value("applicationName").toString();
            data["applicationIcon"] = appObject.value("applicationIcon").toString();
            appList.append(data);
        }
    }

    // sort alphabetically

    std::sort(appList.begin(), appList.end(), [](const QVariant &a, const QVariant &b) {
        return a.toMap().value("applicationName").toString() < b.toMap().value("applicationName").toString();
    });

#endif

    return appList;
}

// open application by package name
void Platform::openApplication(const QString &packageName)
{
#ifdef Q_OS_ANDROID

    QJniObject activity = QNativeInterface::QAndroidApplication::context();
    activity.callMethod<void>(
        "openApplication",
        "(Ljava/lang/String;)V",
        QJniObject::fromString(packageName).object<jstring>());

#else

    Q_UNUSED(packageName);

#endif
}

// return if system clock is in 24 hour format
bool Platform::is24HourFormat()
{
#ifdef Q_OS_ANDROID

    QJniObject activity = QNativeInterface::QAndroidApplication::context();
    return activity.callMethod<jboolean>("is24HourFormat");

#endif

    return true;
}

// return if Android TV OS device
bool Platform::isTelevision()
{
#ifdef Q_OS_ANDROID

    QJniObject activity = QNativeInterface::QAndroidApplication::context();
    return activity.callMethod<jboolean>("isTelevision");

#endif

    return false;
}

void Platform::openSettings()
{
#ifdef Q_OS_ANDROID

    QJniObject activity = QNativeInterface::QAndroidApplication::context();
    activity.callMethod<void>("openSettings");

#endif
}

void Platform::openAppInfo(const QString &packageName)
{
#ifdef Q_OS_ANDROID

    QJniObject activity = QNativeInterface::QAndroidApplication::context();
    activity.callMethod<void>(
        "openAppInfo",
        "(Ljava/lang/String;)V",
        QJniObject::fromString(packageName).object<jstring>());

#endif
}

void Platform::openLetiHomePage()
{
#ifdef Q_OS_ANDROID

    QJniObject activity = QNativeInterface::QAndroidApplication::context();
    activity.callMethod<void>("openLetiHomePage");

#endif
}


void Platform::openLetiHomePlusPage()
{
#ifdef Q_OS_ANDROID

    QJniObject activity = QNativeInterface::QAndroidApplication::context();
    activity.callMethod<void>("openLetiHomePlusPage");

#endif
}
