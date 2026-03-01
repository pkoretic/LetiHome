pragma ComponentBehavior: Bound
import QtQuick

// Best to use with Keys.forwardTo: []
Item 
{
    id: r

    signal longPressed()
    signal shortPressed()
    property alias longPressInterval: longPressTimer.interval
    property int targetKey

    Timer {
        id: longPressTimer
        interval: 600
        onTriggered: r.longPressed()
    }

    Keys.onPressed: (event) => {
        if (event.key === targetKey && !event.isAutoRepeat) {
            event.accepted = true
            longPressTimer.start()
        }
    }

    Keys.onReleased: (event) => {
        if (event.key === targetKey) {
            event.accepted = true
            if (longPressTimer.running) {
                longPressTimer.stop()
                r.shortPressed()
            }
        }
    }
}
