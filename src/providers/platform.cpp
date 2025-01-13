#include <QCoreApplication>
#include <QNetworkInformation>

#include "platform.h"


void Platform::init()
{
    // Listen to network reachability
    QNetworkInformation::loadDefaultBackend();
    auto networkInfo = QNetworkInformation::instance();
    this->setOnline(networkInfo->reachability() == QNetworkInformation::Reachability::Online);
    QObject::connect(networkInfo, &QNetworkInformation::reachabilityChanged, [this](auto reachability) {
        this->setOnline(reachability == QNetworkInformation::Reachability::Online);
    });

    this->setIsTelevision(this->isTelevision());
}

// maybe we will support some other platform in the future
#ifdef Q_OS_ANDROID
#include <QJniObject>

/*
 these are JNI functions called from java
*/

void onPackagesChanged(JNIEnv *env , jobject /* self */, jstring action)
{
    // Convert the jstring (Java string) to a QString
    const char *nativeString = env->GetStringUTFChars(action, nullptr);
    QString actionString = QString::fromUtf8(nativeString);
    env->ReleaseStringUTFChars(action, nativeString);

    QMetaObject::invokeMethod(&Platform::instance(), "packagesChanged", Qt::AutoConnection, Q_ARG(QString, actionString));
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
    JNINativeMethod packagesMethods[] {{ "onPackagesChanged", "(Ljava/lang/String;)V", reinterpret_cast<void *>(onPackagesChanged) }};
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

    QJniObject applications = activity.callObjectMethod("applicationList", "()Ljava/util/Map;");
    auto entriesSet = applications.callObjectMethod("entrySet", "()Ljava/util/Set;");
    auto entriesSetIterator = entriesSet.callObjectMethod("iterator", "()Ljava/util/Iterator;");

    while (entriesSetIterator.callMethod<jboolean>("hasNext"))
    {
        auto entry = entriesSetIterator.callObjectMethod("next", "()Ljava/lang/Object;");
        auto packageName = entry.callObjectMethod("getKey", "()Ljava/lang/Object;").toString();
        auto applicationName = entry.callObjectMethod("getValue", "()Ljava/lang/Object;").toString();

        QVariantMap data;
        data["packageName"] = packageName;
        data["applicationName"] = applicationName;
        appList.append(data);
    }

    // Sort the appList by "applicationName" (case-sensitive)
    std::sort(appList.begin(), appList.end(), [](const QVariant &a, const QVariant &b) {
        QString nameA = a.toMap().value("applicationName").toString();
        QString nameB = b.toMap().value("applicationName").toString();
        return nameA < nameB; // Case-sensitive comparison
    });

#else
    for (int i = 0; i < 20; i++)
    {
        QVariantMap data;
        data["packageName"] = "hr.envizia.letihome";
        data["applicationName"] = "App " + QString::number(i);
        appList.append(data);
    }
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

// open wallpaper picker menu
void Platform::pickWallpaper()
{
#ifdef Q_OS_ANDROID

    QJniObject activity = QNativeInterface::QAndroidApplication::context();
    activity.callMethod<void>("pickWallpaper");

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
