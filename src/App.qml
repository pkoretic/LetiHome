import QtCore
import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls.Material
import QtMultimedia

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

    PlatformProvider { id: platformProvider }
    SettingsProvider { id: settingsProvider }

    // Leti Home default Home Screen
    Home
    {
        id: homeScreen
        anchors.fill: parent

        platformProvider: platformProvider
        settingsProvider: settingsProvider
    }

    // LetiHome About screen, created on demand
    About
    {
        id: aboutPopup
        anchors.centerIn: parent
        width: app.width * 0.9
        height: app.height * 0.9
    }

    // LetiHome Options screen, created on demand
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
