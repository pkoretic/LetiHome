import QtCore
import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls.Material
import QtMultimedia

import "App.js" as App
import "components"
import "providers"

ApplicationWindow
{
    id: app

    title: qsTr("LetiHome")

    // this is set to native resolution on android
    width: 1920
    height: 1080

    visible: true
    visibility: Window.FullScreen

    Material.theme: Material.Dark
    Material.accent: Material.Blue

    // load apps when component is ready
    Component.onCompleted: App.init()

    // when packages are changed (installed/removed) update list
    Connections
    {
        target: platformProvider
        function onAppsChanged() { App.loadApplications() }
    }

    PlatformProvider { id: platformProvider }
    SettingsProvider { id: settingsProvider }

    // background
    Rectangle
    {
        anchors.fill: parent
        gradient: Gradient
        {
             GradientStop { position: 0.0; color: "#111317" }
             GradientStop { position: 0.5; color: "#12151d" }
             GradientStop { position: 1.0; color: "#161f2d" }
        }
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
            Keys.onPressed: event => App.onKeyPress(event)
            onOpenClicked: packageName => App.openApplication(packageName)
            onInfoClicked: packageName => App.openAppInfo(packageName)

        }
    }

    Menu
    {
        id: letiHomeContextMenu
        MenuItem
        {
            text: qsTr("About")
            onTriggered: App.openAbout()
        }
        MenuItem
        {
            text: qsTr("Options")
            onTriggered: App.openOptions()
        }
    }

    // LetiHome About screen
    About
    {
        id: aboutPopup
        anchors.centerIn: parent
        width: app.width * 0.9
        height: app.height * 0.9
    }

    // LetiHome Options screen
    Options
    {
        id: optionsPopup
        anchors.centerIn: parent
        width: app.width * 0.9
        height: app.height * 0.9
        modal: true

        settingsProvider: settingsProvider
    }
}
