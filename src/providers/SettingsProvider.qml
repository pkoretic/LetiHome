pragma ComponentBehavior: Bound
import QtQuick
import QtCore

Settings
{
    id: settings
    property bool showAppNames: false
    property bool alignToBottom: false
    property bool showClock: true
    property bool showDate: true
    property bool useLoremPicsumWallpaper: false

    function init()
    {
        console.info("settingsProvider initialized", showAppNames, alignToBottom)
    }
}
