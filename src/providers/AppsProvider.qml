pragma ComponentBehavior: Bound
import QtCore
import QtQuick

Item
{
    id: appsProvider

    signal appAdded(string packageName, string applicationName)
    signal appRemoved(string packageName)
    signal appDisabled(string packageName)
    signal appShown(string packageName)

    Settings
    {
        id: settings
        property var apps: []
    }

    function init(platformProvider)
    {
        // initialize with all enabled apps by default
        if (!settings.apps?.length)
            settings.apps = getAllApps()

        platformProvider.appsChanged.connect(processAppChange)

        console.info("appsProvider initialized, app count:", settings.apps.length)
    }

    function processAppChange(action, packageName, applicationName)
    {
        console.info("apps changed:", action, packageName, applicationName)
        switch(action)
        {
            case "PACKAGE_ADDED":
                addApp(packageName, applicationName)
            break

            case "PACKAGE_REMOVED":
                removeApp(packageName)
            break
            case "PACKAGE_CHANGED":
                // app can get enabled or disabled which means it's available or not in platform packages
                if (!(getAllApps().some(app => app.packageName === packageName)))
                    appDisabled(packageName)
            break
        }
    }

    function getAllApps()
    {
        return platformProvider.getApps()
    }

    function getApp(packageName)
    {
        return getAllApps().find(app => app.packageName === packageName)
    }

    function getStoredApps()
    {
        return settings.apps
    }

    // returns apps that are not saved
    function getAvailableApps()
    {
        return getAllApps().filter(app => !getStoredApps().some(savedApp => savedApp.packageName === app.packageName))
    }

    function isAppStored(packageName)
    {
        return getStoredApps().some(app => app.packageName === packageName)
    }

    function getStoredApp(packageName)
    {
        return getStoredApps().filter(app => app.packageName === packageName)
    }

    function removeApp(packageName)
    {
        if (!isAppStored(packageName))
            return

        settings.apps = settings.apps.filter(app => app.packageName !== packageName)
        appRemoved(packageName)
    }

    function isAppAvailable(packageName)
    {
        return getAllApps().some(app => app.packageName === packageName)
    }

    // app = packageName, applicationName
    function addApp(packageName, applicationName)
    {
        if (!isAppAvailable(packageName))
            return

        if (applicationName)
            settings.apps.push({packageName, applicationName})
        else
            settings.apps.push(getApp(packageName))

        settings.appsChanged()
        appAdded(packageName, applicationName)
    }

    // appsOrder = [com.example1, com.example2,...]
    function setOrder(appsOrder)
    {
        const reorderedApps = []
        for (const packageName of appsOrder)
           reorderedApps.push(getApp(packageName))

        storeApps(reorderedApps)
    }

    function storeApps(apps)
    {
       settings.apps = apps
    }
}
