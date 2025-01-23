#ifndef IMAGEPROVIDER_H
#define IMAGEPROVIDER_H

#include <QQuickImageProvider>

class IconProvider : public QQuickImageProvider
{
public:
    explicit IconProvider();
    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize);
    QImage getApplicationIcon(const QString &packageName);
};

#endif // IMAGEPROVIDER_H
