#include "keymapper.h"
#include <QCoreApplication>

KeyMapper::KeyMapper(QObject *parent) : QObject(parent) {}

bool KeyMapper::eventFilter(QObject *obj, QEvent *event) {
    if (event->type() == QEvent::KeyPress ||
        event->type() == QEvent::KeyRelease) {

        QKeyEvent *keyEvent = static_cast<QKeyEvent *>(event);
        if (keyEvent->key() == Qt::Key_Return) {
            QKeyEvent newEvent(
                event->type(),
                Qt::Key_Enter,
                keyEvent->modifiers(),
                keyEvent->nativeScanCode(),
                keyEvent->nativeVirtualKey(),
                keyEvent->nativeModifiers(),
                keyEvent->text(),
                keyEvent->isAutoRepeat(),
                keyEvent->count()
            );
            QCoreApplication::sendEvent(obj, &newEvent);
            return newEvent.isAccepted();
        }
    }
    return QObject::eventFilter(obj, event);
}