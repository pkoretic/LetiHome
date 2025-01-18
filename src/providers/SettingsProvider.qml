pragma ComponentBehavior: Bound
import QtQuick
import QtCore

Settings
{
    id: settings
    property bool showAppNames: true

    function init()
    {
        console.info("settingsProvider initialized")
    }
}
