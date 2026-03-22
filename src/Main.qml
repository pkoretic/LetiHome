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
    Material.accent: Material.Indigo

    // providers / domain-models
    AppsProvider     { id: appsProvider }
    SettingsProvider { id: settingsProvider }
    PlatformProvider { id: platformProvider }
    NavigationProvider { id: navigationProvider }

    Component.onCompleted:
    {
        // initialize providers in the correct order (dependencies)
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

        // start noise audio if enabled in settings
        updateNoisePlayback()
    }

    // Handle noise audio playback based on settings and app state
    function updateNoisePlayback()
    {
        if (Qt.application.state !== Qt.ApplicationActive) {
            noisePlayer.stop()
            return
        }

        if (settingsProvider.playWhiteNoise) {
            noisePlayer.source = "../assets/whitenoise.wav"
            noisePlayer.play()
        } else if (settingsProvider.playInaudibleNoise) {
            noisePlayer.source = "../assets/inaudible.wav"
            noisePlayer.play()
        } else {
            noisePlayer.stop()
        }
    }

    // main background noise audio player
    MediaPlayer
    {
        id: noisePlayer
        audioOutput: AudioOutput {}
        loops: MediaPlayer.Infinite
    }

    // react to changes in noise audio settings
    Connections 
    {
        target: settingsProvider
        function onPlayWhiteNoiseChanged() { app.updateNoisePlayback() }
        function onPlayInaudibleNoiseChanged() { app.updateNoisePlayback() }
    }

    // pause noise audio when app is not active
    Connections
    {
        target: Qt.application
        function onStateChanged() { app.updateNoisePlayback() }
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
        platformProvider: platformProvider
    }
}
