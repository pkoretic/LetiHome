pragma ComponentBehavior: Bound
import QtCore
import QtQuick

Item
{
    id: appsProvider

    signal appAdded(string packageName, string applicationName)
    signal appRemoved(string packageName)
    signal appChanged(string packageName)

    Settings
    {
        id: settings
        property var apps: []
    }

    function init(platformProvider)
    {
        if (!settings.apps?.length)
            settings.apps = platformProvider.getApps()

        platformProvider.appsChanged.connect(processAppChange)

        console.info("appsProvider initialized, app count:", settings.apps.length)
    }

    function processAppChange(action, packageName, applicationName)
    {
        console.info("apps changed:", action, packageName, applicationName)
        switch(action)
        {
            case "PACKAGE_CHANGED":
                appChanged(packageName)
            break

            case "PACKAGE_ADDED":
                addApp(packageName, applicationName)
            break

            case "PACKAGE_REMOVED":
                removeApp(packageName)
            break
        }
    }

    function getAllApps()
    {
        return settings.apps
    }

    function getVisibleApps()
    {
        return settings.apps.filter(app => app && !app.hidden)
    }

    function getApp(packageName)
    {
        for (const app of settings.apps)
            if (app.packageName === packageName)
                return app
    }

    function hideApp(packageName)
    {
        const app = getApp(packageName)
        app.hidden = true
        settings.appsChanged()
    }

    function removeApp(packageName)
    {
        settings.apps = settings.apps.filter(app => app.packageName !== packageName)
        appRemoved(packageName)
    }

    function addApp(packageName, applicationName)
    {
        settings.apps.push({packageName, applicationName})
        appAdded(packageName, applicationName)
    }

    // appsOrder = [com.example1, com.example2,...]
    function setOrder(appsOrder)
    {
        const reorderedApps = []
        for (const packageName of appsOrder)
           reorderedApps.push(getApp(packageName))

        saveApps(reorderedApps)
    }

    function saveApps(apps)
    {
       settings.apps = apps
    }
}
