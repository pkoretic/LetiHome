#ifndef IMAGEPROVIDER_H
#define IMAGEPROVIDER_H

#include <QQuickImageProvider>

class ImageProvider : public QQuickImageProvider
{
public:
    explicit ImageProvider();
    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize);
    QImage getApplicationIcon(const QString &packageName);
};

#endif // IMAGEPROVIDER_H
