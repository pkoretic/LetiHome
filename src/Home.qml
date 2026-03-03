pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Material
import QtQml

import "components"

Rectangle
{
    id: r

    required property var platformProvider
    required property var settingsProvider
    required property var appsProvider
    required property var navigationProvider

    ListModel { id: appsModel }

    // load apps when component is ready
    Component.onCompleted:
    {
        // screen dimensions are known on android only after the main window is shown, so we set them here
        r.platformProvider.setScreenDimensions(r.width, r.height)

        loadApps()

        // when packages are changed update list
        appsProvider.onAppAdded.connect((packageName) => addApp(packageName))
        appsProvider.onAppRemoved.connect(packageName => removeApp(packageName))
        appsProvider.onAppDisabled.connect(packageName => removeApp(packageName))
    }

    function loadApps()
    {   // load stored apps | updated only if changed
        const apps = appsProvider.getStoredApps()
        for (var i = 0; i < apps.length; i++)
            appsModel.set(i, apps[i])
    }

    function addApp(packageName)
    {
        const app = appsProvider.getApp(packageName)
        appsModel.append(app)
    }

    function removeApp(packageName)
    {
        for (var i = 0; i < appsModel.count; i++)
            if (appsModel.get(i).packageName === packageName)
                return appsModel.remove(i)
    }

    function openApplication(packageName)
    {
        console.info("opening application:", packageName)

        // open internal about page
        if(packageName === "hr.envizia.letihomeplus")
            r.navigationProvider.go("/about")
        else
            r.platformProvider.openApplication(packageName)
    }

    function openAppInfo(packageName)
    {
        platformProvider.openAppInfo(packageName)
    }

    gradient: Gradient
    {
         GradientStop { position: 0.0; color: Qt.color("#0D1B2A") }
         GradientStop { position: 0.5; color: Qt.color("#1B263B") }
         GradientStop { position: 1.0; color: Qt.color("#0D1B2A") }
    }

    Image
    {
        id: wallpaper
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        visible: r.settingsProvider.useLoremPicsumWallpaper

        // We have to wait for the main window width and height to be set on android
        Component.onCompleted: source = Qt.binding(() => r.settingsProvider.wallpaperUrl)

        Rectangle
        {
            anchors.fill: parent
            color: Qt.color("#AA000000") // semi-transparent overlay
        }
    }

    // Top Date and Time display with WiFi status
    TopBar
    {
        z: 1
        id: topBar
        y: 20
        x: 20
        width: parent.width - 40 // x * 2

        isOnline: r.platformProvider.isOnline
        isEthernet: r.platformProvider.isEthernet
        isTelevision: r.platformProvider.isTelevision
        is24HourFormat: r.platformProvider.is24HourFormat()
        showClock: r.settingsProvider.showClock
        showDate: r.settingsProvider.showDate
        KeyNavigation.down: appsLoader
        Keys.onBackPressed: appsLoader.focus = true
        onSettingsClicked: r.navigationProvider.go("/options")
        onNetworkClicked: r.platformProvider.openNetworkSettings()
        onTvInputClicked: r.navigationProvider.go("/options", { initialTab: "system" })
        onHelpClicked: r.navigationProvider.go("/about")

         // if showTopIcons is enabled always show icons, otherwise show only when focused
         showIcons: r.settingsProvider.showTopIcons || activeFocus
    }

    Loader
    {
        id: appsLoader
        focus: true
        x: 40
        y: r.settingsProvider.alignToBottom ? (parent.height - height - 20) : (topBar.height + 40) // 20 is spacing from top or bottom, 40 is topBar.y * 2
        width: parent.width - 80 // x * 2
        height: sourceComponent === appsListComponent ? (item?.delegateHeight) : Math.min((parent.height - topBar.height - topBar.y * 2 - 20), item?.childrenRect.height) // if list use delegate height, if grid use available height but not more than needed
         Keys.onUpPressed: topBar.focus = true

        // load apps list or grid based on settings
        sourceComponent: settingsProvider.showAsList ? appsListComponent : appsGridComponent
    }

    Component
    {
        id: appsListComponent

        AppsList
        {
            id: appsList
            focus: true
            model: appsModel
            appsShown: r.settingsProvider.appsShown
            isTelevision: r.platformProvider.isTelevision
            showAppLabels: r.settingsProvider.showAppNames
            onOpenClicked: packageName => r.openApplication(packageName)
            onInfoClicked: packageName => r.openAppInfo(packageName)
            onRemoveClicked: packageName => r.appsProvider.removeApp(packageName)
            onOrderChanged: appsOrder => r.appsProvider.setOrder(appsOrder)
        }
    }

    Component
    {
        id: appsGridComponent

        AppsGrid
        {
            id: appsGrid
            focus: true
            model: appsModel
            appsShown: r.settingsProvider.appsShown
            isTelevision: r.platformProvider.isTelevision
            showAppLabels: r.settingsProvider.showAppNames
            onOpenClicked: packageName => r.openApplication(packageName)
            onInfoClicked: packageName => r.openAppInfo(packageName)
            onRemoveClicked: packageName => r.appsProvider.removeApp(packageName)
            onOrderChanged: appsOrder => r.appsProvider.setOrder(appsOrder)
        }
    }
}