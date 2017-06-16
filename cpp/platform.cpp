#include <QImage>

#include "platform.h"

// maybe we will support some other platform in the future
#ifdef Q_OS_ANDROID
#include <QtAndroidExtras>
#include <QtAndroid>

/*
 these are JNI functions called from java
*/

void onPackagesChanged(JNIEnv /* *env */, jobject /* self */)
{
    QMetaObject::invokeMethod(&Platform::instance(), "packagesChanged", Qt::AutoConnection);
}

// called on JNI LOAD, register native methods to corresponding classes
jint JNICALL JNI_OnLoad(JavaVM* vm, void*)
{
    JNIEnv* env;

    if (vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) != JNI_OK)
        return JNI_ERR;

    // get main receiver class
    QAndroidJniObject receiver = QAndroidJniObject("com/qaap/letihome/PackagesChangedReceiver");
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

    QAndroidJniObject applications = QtAndroid::androidActivity().callObjectMethod("applicationList", "()Ljava/util/Map;");
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

    #endif

    return appList;
}

// launch application by package name
void Platform::launchApplication(const QString &packageName)
{
    #ifdef Q_OS_ANDROID

    QtAndroid::androidActivity().callMethod<void>(
        "launchApplication",
        "(Ljava/lang/String;)V",
        QAndroidJniObject::fromString(packageName).object<jstring>());

    #endif
}

// open wallpaper picker menu
void Platform::pickWallpaper()
{
    #ifdef Q_OS_ANDROID

    QtAndroid::androidActivity().callMethod<void>("pickWallpaper");

    #endif
}
