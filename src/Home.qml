pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Material

import "components"

Rectangle
{
    id: homeView

    property var platformProvider
    property var settingsProvider
    property var appsProvider

    ListModel { id: appsModel }

    // load apps when component is ready
    Component.onCompleted: loadApplications()

    // when packages are changed (installed/removed) update list
    Connections
    {
        // todo: move to appsProvider
        target: appsProvider
        function onAppAdded(packageName, applicationName) {
            appsModel.append({ packageName: packageName, applicationName: applicationName })
        }

        function onAppRemoved(packageName) {
            for (var i = 0; i < appsModel.count; i++)
            {
                if (appsModel.get(i).packageName === packageName)
                {
                    appsModel.remove(i)
                    break
                }
            }
        }

        function onAppChanged(packageName) {
            // TODO
        }
    }

    function loadApplications()
    {
        const apps = appsProvider.getVisibleApps()
        for (var i = 0; i < apps.length; i++)
            appsModel.set(i, apps[i])
    }

    function openApplication(packageName)
    {
        // open internal pages
        if(packageName === "hr.envizia.letihome")
            letiHomeContextMenu.popup(appsGrid.currentItem, aboutMenu)
        else
            platformProvider.openApplication(packageName)
    }

    function openAbout()
    {
        aboutPopup.open()
    }

    function openOptions()
    {
        optionsPopup.open()
    }

    function openAppInfo(packageName)
    {
        platformProvider.openAppInfo(packageName)
    }

    function openSettings()
    {
        platformProvider.openSettings()
    }

    function openLetiHomePage()
    {
        platformProvider.openLetiHomePage()
    }

    function openContextualMenu()
    {
        appsGrid.openContextualMenu()
    }

    gradient: Gradient
    {
         GradientStop { position: 0.0; color: "#111317" }
         GradientStop { position: 0.5; color: "#12151d" }
         GradientStop { position: 1.0; color: "#161f2d" }
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
            isOnline: platformProvider.isOnline
            is24HourFormat: platformProvider.is24HourFormat()
        }

        // Main Content display
        AppsGrid
        {
            id: appsGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter
            model: appsModel

            focus: true

            isTelevision: platformProvider.isTelevision
            showAppLabels: settingsProvider.showAppNames
            onOpenClicked: packageName => openApplication(packageName)
            onInfoClicked: packageName => openAppInfo(packageName)
            onAppHidden: packageName => appsProvider.hideApp(packageName)
            onOrderChanged: appsOrder => appsProvider.setOrder(appsOrder)
        }
    }

    Menu
    {
        id: letiHomeContextMenu
        MenuItem
        {
            id: aboutMenu
            text: qsTr("About")
            onTriggered: openAbout()
        }
        MenuItem
        {
            text: qsTr("Options")
            onTriggered: openOptions()
        }
    }
}
