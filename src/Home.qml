pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Material

import "components"

Rectangle
{
    id: homeView

    required property var platformProvider
    required property var settingsProvider
    required property var appsProvider
    required property var navigationProvider

    ListModel { id: appsModel }

    // load apps when component is ready
    Component.onCompleted:
    {
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
        // open internal context options
        if(packageName === "hr.envizia.letihomeplus")
        {
            const x = appsGrid.currentItem.x + appsGrid.currentItem.width / 2
            const y = appsGrid.currentItem.y + appsGrid.currentItem.height / 2
            letiHomeContextMenu.popup(x, y, settingsMenu)
        }
        else
        {
            platformProvider.openApplication(packageName)
        }
    }

    function openAppInfo(packageName)
    {
        platformProvider.openAppInfo(packageName)
    }

    gradient: Gradient
    {
         GradientStop { position: 0.0; color: "#0D1B2A" }
         GradientStop { position: 0.5; color: "#1B263B" }
         GradientStop { position: 1.0; color: "#0D1B2A" }
    }

    // main layout used for padding, spacing and layout
    ColumnLayout
    {
        anchors.fill: parent
        anchors.margins: 40
        spacing: 20

        // Top Date and Time display with WiFi status
        TopBar
        {
            z: 1
            Layout.fillWidth: true
            Layout.preferredHeight: childrenRect.height
            Layout.alignment: Qt.AlignTop
            isOnline: platformProvider.isOnline
            is24HourFormat: platformProvider.is24HourFormat()
            showClock: settingsProvider.showClock
            showDate: settingsProvider.showDate
            KeyNavigation.down: appsGrid
            onSettingsClicked: navigationProvider.go("/options")
        }

        // Main Content display
        AppsGrid
        {
            id: appsGrid
            Layout.fillWidth: true
            Layout.preferredHeight: childrenRect.height
            Layout.alignment: Qt.AlignHCenter | (settingsProvider.alignToBottom ? Qt.AlignBottom : Qt.AlignTop)
            model: appsModel

            focus: true

            isTelevision: platformProvider.isTelevision
            showAppLabels: settingsProvider.showAppNames
            onOpenClicked: packageName => openApplication(packageName)
            onInfoClicked: packageName => openAppInfo(packageName)
            onRemoveClicked: packageName => appsProvider.removeApp(packageName)
            onOrderChanged: appsOrder => appsProvider.setOrder(appsOrder)

            Menu
            {
                id: letiHomeContextMenu
                MenuItem
                {
                    id: settingsMenu
                    text: qsTr("Settings")
                    onTriggered: navigationProvider.go("/options")
                }
                MenuItem
                {
                    text: qsTr("About")
                    onTriggered: navigationProvider.go("/about")
                }
            }
        }
    }

}
