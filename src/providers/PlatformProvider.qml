pragma ComponentBehavior: Bound
import QtCore
import QtQuick

Item
{
    signal appsChanged(string action, string packageName, string applicationName)

    property bool isOnline: _Platform.isOnline
    property bool isTelevision: _Platform.isTelevision

    function init()
    {
        // when packages are changed (installed/removed/enabled/disabled)
        _Platform.onPackagesChanged.connect(appsChanged)

        console.info("platformProvider initialized")
    }

    function is24HourFormat()
    {
        return _Platform.is24HourFormat()
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

    function getApps()
    {
        return _Platform.applicationList()
    }

}
