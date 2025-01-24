pragma ComponentBehavior: Bound
import QtQuick
import QtCore

Settings
{
    id: settings
    property bool showAppNames: false
    property bool alignToBottom: false

    function init()
    {
        console.info("settingsProvider initialized", showAppNames, alignToBottom)
    }
}
