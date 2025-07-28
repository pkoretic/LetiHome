pragma ComponentBehavior: Bound
import QtQuick
import QtCore

Settings
{
    id: settings
    property bool showAppNames: false
    property bool alignToBottom: true
    property bool showClock: true
    property bool showDate: true
    property bool useLoremPicsumWallpaper: false
    property bool showAsList: true
    property int appsShown: 7
    property bool isFirstRun: true

    function init()
    {
        console.info("settingsProvider initialized", showAppNames, alignToBottom)
    }
}
