import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls.Material
import QtMultimedia

import "components"
import "App.js" as Controller

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

    property bool isTelevision: _Platform.isTelevision
    property bool isOnline: _Platform.isOnline
    property bool is24HourFormat: _Platform.is24HourFormat()

    // load apps when component is ready
    Component.onCompleted: Controller.init()

    // when packages are changed (installed/removed) update list
    Connections
    {
        id: connections
        target: _Platform
        function onPackagesChanged() { Controller.loadApplications() }
    }

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
            isOnline: app.isOnline
            is24HourFormat: app.is24HourFormat
        }

        // Main Content display
        AppsGrid
        {
            id: appsGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter

            focus: true

            isTelevision: app.isTelevision
            onKeyPressed: event => Controller.onKeyPress(event)
            onClicked: packageName => Controller.openApplication(packageName)
        }
    }

    // LetiHome About / Options screen
    About { id: aboutPopup }
}
