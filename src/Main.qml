pragma ComponentBehavior: Bound

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

    // providers / domain-models
    AppsProvider     { id: appsProvider }
    SettingsProvider { id: settingsProvider }
    PlatformProvider { id: platformProvider }
    NavigationProvider { id: navigationProvider }

    Component.onCompleted:
    {
        settingsProvider.init()
        platformProvider.init()
        appsProvider.init(platformProvider)

        navigationProvider.init({
            "/options": optionsPopup,
            "/about": aboutPopup ,
            "/systemsettings": platformProvider.openSystemSettings,
            "/appStore": platformProvider.openAppStore
        })

        homeScreen.visible = true

        if (settingsProvider.isFirstRun) {
            navigationProvider.go("/about")
            settingsProvider.isFirstRun = false
        }
    }

    // Leti Home default Home Screen
    Home
    {
        id: homeScreen
        anchors.fill: parent

        visible: false
        enabled: visible

        platformProvider: platformProvider
        settingsProvider: settingsProvider
        appsProvider: appsProvider
        navigationProvider: navigationProvider
    }

    // LetiHome About screen, created on demand
    About
    {
        id: aboutPopup
        anchors.centerIn: parent
        width: app.width * 0.9
        height: app.height * 0.9

        navigationProvider: navigationProvider
    }

    // LetiHome Options screen, created on demand
    Options
    {
        id: optionsPopup
        anchors.centerIn: parent
        width: app.width * 0.9
        height: app.height * 0.9

        appsProvider: appsProvider
        settingsProvider: settingsProvider
        navigationProvider: navigationProvider
    }

    ListView
    {
        id: list
        width: parent.width
        height: 300
        model: _Platform.getNextPrograms()
        orientation: ListView.Horizontal
        delegate:
        Image
        {
            width: 200
            height: 100
            required property var modelData
            source: "data:image/webp;base64," + modelData["posterImage"]

            Text {
                anchors.bottom: parent.bottom
                text: modelData["title"]
            }
        }
    }

}
