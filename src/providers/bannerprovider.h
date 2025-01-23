#ifndef BANNERPROVIDER_H
#define BANNERPROVIDER_H

#include <QQuickImageProvider>

class BannerProvider : public QQuickImageProvider
{
public:
    explicit BannerProvider();
    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize);
    QImage getApplicationBanner(const QString &packageName);
};

#endif // BANNERPROVIDER_H
