#pragma once
#include <QObject>
#include <QEvent>
#include <QKeyEvent>

class KeyMapper : public QObject {
    Q_OBJECT
public:
    explicit KeyMapper(QObject *parent = nullptr);
protected:
    bool eventFilter(QObject *obj, QEvent *event) override;
};