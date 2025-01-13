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

    // load apps when component is ready
    Component.onCompleted: init()

    // when packages are changed (installed/removed) update list
    Connections
    {
        target: platformProvider
        function onAppsChanged() { loadApplications() }
    }

    function init()
    {
        loadApplications()
    }

    // controllers
    function loadApplications()
    {
        appsGrid.model = platformProvider.applicationList()
    }

    function openApplication(packageName)
    {
        // open internal pages
        if(packageName === "hr.envizia.letihome")
            letiHomeContextMenu.popup(appsGrid.currentItem)
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

    function onKeyPress(event)
    {
        console.debug("keyPressed", event.key)

        event.accepted = true
        const packageName = appsGrid.model[appsGrid.currentIndex].packageName

        switch(event.key)
        {
            case Qt.Key_Return:
            case Qt.Key_Enter:
                openApplication(packageName)
            break

            case Qt.Key_Back:
            case Qt.Key_Escape:
                openContextualMenu()
            break

            case Qt.Key_Menu:
                openSettings()
            break

            default:
                event.accepted = false
        }
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

            focus: true

            isTelevision: platformProvider.isTelevision
            showAppLabels: settingsProvider.showAppNames
            Keys.onPressed: event => homeView.onKeyPress(event)
            onOpenClicked: packageName => openApplication(packageName)
            onInfoClicked: packageName => openAppInfo(packageName)

        }
    }

    Menu
    {
        id: letiHomeContextMenu
        MenuItem
        {
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
