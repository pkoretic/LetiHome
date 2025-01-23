#include <QCoreApplication>
#if defined(Q_OS_ANDROID)
#include <QJniEnvironment>
#include <QJniObject>
#endif
#include <QDebug>

#include "bannerprovider.h"

BannerProvider::BannerProvider()
    : QQuickImageProvider(QQuickImageProvider::Image)
{
}
QImage BannerProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize)
{
    Q_UNUSED(size);
    Q_UNUSED(requestedSize);

    return getApplicationBanner(id);
}

QImage BannerProvider::getApplicationBanner(const QString &packageName)
{
    QImage image;

#ifdef Q_OS_ANDROID
    QJniObject activity = QNativeInterface::QAndroidApplication::context();
    QJniObject appIcon = activity.callObjectMethod("getApplicationBanner",
      "(Ljava/lang/String;)[B",
      QJniObject::fromString(packageName).object<jstring>());

    QJniEnvironment env;
    jbyteArray iconDataArray = appIcon.object<jbyteArray>();

    if (!iconDataArray)
    {
        qWarning() << Q_FUNC_INFO << "No icon data";

        return image;
    }

    jsize iconSize = env->GetArrayLength(iconDataArray);

    if (iconSize > 0)
    {
        jbyte *icon = env->GetByteArrayElements(iconDataArray, 0);
        image = QImage(QImage::fromData((uchar *)icon, iconSize, "PNG"));
        env->ReleaseByteArrayElements(iconDataArray, icon, JNI_ABORT);
    }
#else
    Q_UNUSED(packageName);

    static const char * const start_xpm[] = {
        "2 2 2 1",
        "r c #FF0000",
        "b c #FFEEBB",
        "aa",
        "bb"
    };

    image = QImage(start_xpm);

#endif
    return image;
}