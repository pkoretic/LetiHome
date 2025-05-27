pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls.Material

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

    // Platform abstraction inserted from main.cpp
    property bool isTelevision: _platform.isTelevision
    property bool isOnline: _platform.isOnline
    property bool is24HourFormat: _platform.is24HourFormat()

    // main date object
    property date currentDate: new Date()

    // load apps when component is ready
    Component.onCompleted:
    {
        loadApplications()
        if (settings.firstRun)
        {
            settings.firstRun = false
            // open about popup on first run
            aboutPopup.open()
        }
    }

    function loadApplications()
    {
        appGrid.model = _platform.applicationList()
    }

    function openApplication(packageName)
    {
        if(packageName === "hr.envizia.letihome")
            aboutPopup.open()
        else
            _platform.openApplication(packageName)
    }

    function openAppInfo(packageName)
    {
        _platform.openAppInfo(packageName)
    }

    function openSettings()
    {
        _platform.openSettings()
    }

    function openLetiHomePage()
    {
        _platform.openLetiHomePage()
    }

    function openLetiHomePlusPage()
    {
        _platform.openLetiHomePlusPage()
    }

    function updateDate()
    {
        app.currentDate = new Date()
    }

    // create color for a text input or index
    property var string_colors: [ "#115883", "#536173", "#33b679", "#aeb857", "#df5948", "#855e86", "#ae6b23", "#547bca", "#c75c5c"]

    function colorByIndex(index)
    {
        return string_colors[index % string_colors.length]
    }

    Settings
    {
        id: settings
        property bool firstRun: true
    }

    // when packages are changed (installed/removed) update list
    Connections
    {
        id: connections
        target: _platform
        function onPackagesChanged() { loadApplications() }
    }

    // background
    Rectangle
    {
        anchors.fill: parent
        gradient: Gradient
        {
            GradientStop { position: 0.0; color: "#0D1B2A" }
            GradientStop { position: 0.5; color: "#1B263B" }
            GradientStop { position: 1.0; color: "#0D1B2A" }
        }
    }

    // update in acceptable interval and ignore updates if application is not active (another app open)
    Timer
    {
        running: Application.state == Qt.ApplicationActive
        interval: 5000
        repeat: true
        triggeredOnStart: true
        onTriggered: updateDate()
    }

    // Layout used for padding, spacing and layout
    ColumnLayout
    {
        anchors.fill: parent
        anchors.margins: 40
        spacing: 20

        Item
        {
            Layout.fillWidth: true
            Layout.preferredHeight: childrenRect.height

            z: 1

            // clock in locale format depending if 24 hour format is set in the system
            Text
            {
                id: datetime
                text: Qt.formatTime(app.currentDate, app.is24HourFormat ? "hh:mm" : "hh:mm ap")
                font.pixelSize: 22
                color: "#ffffff"
                style: Text.Outline
            }

            Row
            {
                anchors.right: parent.right
                spacing: 10

                Image
                {
                    source: "network-%1.svg".arg(app.isOnline ? "online" : "offline")
                    height: datetime.height - 10
                    width: height
                    anchors.verticalCenter: parent.verticalCenter
                }

                // date in system locale format
                Text
                {
                    text: app.currentDate.toDateString()
                    font.pixelSize: 22
                    color: "#ffffff"
                    style: Text.Outline
                }
            }
        }

        // main application grid
        GridView
        {
            id: appGrid

            boundsBehavior: GridView.StopAtBounds

            focus: true

            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter

            cellWidth: (width / 5) |0
            cellHeight: cellWidth * 0.5625 // 9/16

            Keys.onReturnPressed: openApplication(appGrid.model[appGrid.currentIndex].packageName)
            Keys.onEnterPressed: openApplication(appGrid.model[appGrid.currentIndex].packageName)
            Keys.onBackPressed: openAppInfo(appGrid.model[appGrid.currentIndex].packageName)
            Keys.onEscapePressed: openAppInfo(appGrid.model[appGrid.currentIndex].packageName)
            Keys.onMenuPressed: openAppInfo(appGrid.model[appGrid.currentIndex].packageName)

            delegate: Rectangle
            {
                id: delegate
                property bool isCurrentItem: GridView.isCurrentItem
                property bool isTVBanner: image.sourceSize.width > image.sourceSize.height

                width: GridView.view.cellWidth - 20
                height: width * 0.5625 // 9/16

                // TVBanner covers the background fully
                color: isTVBanner ? "#ffffff" : colorByIndex(index)

                z: delegate.isCurrentItem ? 1 : 0
                scale: delegate.isCurrentItem ? 1.3 : 1
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }

                required property int index
                required property var modelData

                Image
                {
                    id: image

                    anchors.fill: parent
                    anchors.margins: delegate.isTVBanner ? 0 : 15
                    source: "image://icon/" + delegate.modelData.packageName
                    cache: true
                    fillMode: Image.PreserveAspectFit
                }

                // app name background so it's readable on any background image
                Rectangle
                {
                    visible: app.isTelevision && delegate.isCurrentItem
                    width: parent.width
                    height: appName.height
                    anchors.bottom: parent.bottom
                    color: "#a6000000"
                }

                // app name
                Text
                {
                    id: appName
                    x: 4
                    width: parent.width - x * 2
                    text: delegate.modelData.applicationName
                    color: "#ffffff"
                    elide: Text.ElideRight
                    anchors.bottom: parent.bottom
                    visible: delegate.isCurrentItem || !app.isTelevision
                    horizontalAlignment: Text.AlignHCenter
                }

                // border around current item
                Rectangle
                {
                    anchors.fill: parent
                    visible: delegate.isCurrentItem
                    color: "transparent"
                    border.width: 1
                    border.color: "#222222"
                }

                // open application on mouse click/finger tap
                MouseArea
                {
                    anchors.fill: parent
                    onClicked:
                    {
                        appGrid.currentIndex = delegate.index
                        openApplication(delegate.modelData.packageName)
                    }
                }
            }
        }
    }

    Popup
    {
        id: aboutPopup

        width: parent.width * 0.9
        height: parent.height * 0.9
        anchors.centerIn: parent
        modal: true
        focus: true
        closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape

        Column
        {
            anchors.centerIn: parent
            spacing: 20

            Label
            {
                textFormat: Text.StyledText
                font.pixelSize: 20
                text: `<p>Thank you for using <strong>LetiHome</strong> application!</p><br/>
                <strong>LetiHome</strong> is a lightweight <u>open-source</u> app launcher application<br/>
                that aims to works on as many TV devices as possible, <br/>especially low power ones.<br/><br/>
                As there is <u>zero</u> data collection, please provide your review!<br/><br/>
                <strong>OK</strong> opens current application.<br/>
                <strong>Menu</strong> or <strong>Back</strong> opens application info <br/>where app can be disabled/hidden.<br/>
                <br/>
                <strong> LetiHome Plus</strong> is available for those who want to support development of this application.<br/>
                <br/>
                This popup can be shown again by opening <strong>LetiHome</strong> application from the app list.
                `
            }

            Row
            {
                spacing: 20

                Button
                {
                    text: "Open System Settings"
                    height: 60
                    highlighted: activeFocus
                    Keys.onReturnPressed: clicked()
                    Keys.onEnterPressed: clicked()
                    onClicked: openSettings()

                    KeyNavigation.right: reviewButton
                }

                Button
                {
                    id: reviewButton
                    text: "Leave a review"
                    height: 60
                    highlighted: activeFocus
                    Keys.onReturnPressed: clicked()
                    Keys.onEnterPressed: clicked()
                    onClicked: openLetiHomePage()

                    KeyNavigation.right: closeButton
                }

                Button
                {
                    id: closeButton
                    text: "Close"
                    height: 60
                    focus: true
                    highlighted: activeFocus
                    Keys.onReturnPressed: clicked()
                    Keys.onEnterPressed: clicked()
                    onClicked: aboutPopup.close()
                    KeyNavigation.right: getPlus
                }

                Button
                {
                    id: getPlus
                    text: "Get LetiHome Plus"
                    height: 60
                    focus: true
                    highlighted: activeFocus
                    Keys.onReturnPressed: clicked()
                    Keys.onEnterPressed: clicked()
                    onClicked: openLetiHomePlusPage()
                }
            }
        }
    }
}
