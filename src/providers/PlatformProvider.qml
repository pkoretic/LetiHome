import QtCore
import QtQuick

Item
{
    property var appsList: []
    signal appsChanged(string action)

    property bool isOnline: _Platform.isOnline
    property bool isTelevision: _Platform.isTelevision

    function is24HourFormat()
    {
        return _Platform.is24HourFormat()
    }

    // when packages are changed (installed/removed/enabled/disabled) update list
    Connections
    {
        target: _Platform
        function onPackagesChanged(action) {
            appsChanged(action)
        }
    }

    function openApplication(packageName)
    {
        _Platform.openApplication(packageName)
    }
    function openAppInfo(packageName)
    {
        _Platform.openAppInfo(packageName)
    }

    function openSettings()
    {
        _Platform.openSettings()
    }

    function openLetiHomePage()
    {
        _Platform.openLetiHomePage()
    }

}
