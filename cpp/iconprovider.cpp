#include "iconprovider.h"

#include <QDebug>

#if defined(Q_OS_ANDROID)
#include <QtAndroidExtras>
#include <QtAndroid>
#endif

ImageProvider::ImageProvider()
    : QQuickImageProvider(QQuickImageProvider::Image)
{
}
QImage ImageProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize)
{
    Q_UNUSED(size);
    Q_UNUSED(requestedSize);

    return getApplicationIcon(id);
}

QImage ImageProvider::getApplicationIcon(const QString &packageName)
{
    QImage image;

#ifdef Q_OS_ANDROID
    QAndroidJniObject appIcon = QtAndroid::androidActivity().callObjectMethod("getApplicationIcon",
    "(Ljava/lang/String;)[B",
    QAndroidJniObject::fromString(packageName).object<jstring>());

    QAndroidJniEnvironment env;
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
    image = QImage("://icon/application.png");

#endif
    return image;
}
