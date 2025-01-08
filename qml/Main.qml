import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls.Material

Window
{
    id: root

    title: qsTr("LetiHome")

    // this is set to native resolution on android
    width: 1920
    height: 1080

    visible: true
    visibility: Window.FullScreen

    Material.theme: Material.Dark
    Material.accent: Material.Blue

    property bool isTelevision: __platform.isTelevision
    property bool isOnline: __platform.isOnline

    // main date object
    property date currentDate: new Date()

    // load apps when component is ready
    Component.onCompleted: loadApplications()

    // when packages are changed (installed/removed) update list
    Connections
    {
        id: connections
        target: __platform
        function onPackagesChanged() { loadApplications() }
    }

    // controllers
    function loadApplications() { appGrid.model = __platform.applicationList() }
    function openApplication(packageName) { if(packageName === "hr.envizia.letihome") aboutPopup.open(); else __platform.openApplication(packageName) }
    function openAppInfo(packageName) { __platform.openAppInfo(packageName) }
    function openSettings() { __platform.openSettings() }
    function openLetiHomePage() { __platform.openLetiHomePage() }

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

    // clock and date timer
    // update in acceptable interval and ignore updates if application is not active (another app open)
    Timer
    {
        running: Qt.application.active
        interval: 5000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.currentDate = new Date()
    }

    // wrapper item used for padding, spacing and layout
    ColumnLayout
    {
        anchors.fill: parent
        anchors.margins: 40
        spacing: 20

        Item
        {
            Layout.fillWidth: true
            Layout.preferredHeight: datetime.height

            z: 1

            // clock in locale format depending if 24 hour format is set in the system
            Text
            {
                id: datetime
                text: Qt.formatTime(root.currentDate, __platform.is24HourFormat() ? "hh:mm" : "hh:mm ap")
                font.pixelSize: 22
                color: "#ffffff"
                style: Text.Outline
            }

            Row
            {
                anchors.right: parent.right
                spacing: 20

                Image
                {
                    source: "network-%1.svg".arg(isOnline ? "online" : "offline")
                    height: datetime.height - 10
                    width: height
                    anchors.verticalCenter: parent.verticalCenter
                }

                // date in system locale format
                Text
                {
                    text: root.currentDate.toDateString()
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

            Keys.onPressed: function(event)
            {
                event.accepted = true
                const packageName = appGrid.model[appGrid.currentIndex].packageName

                switch(event.key)
                {
                    case Qt.Key_Return:
                    case Qt.Key_Enter:
                        openApplication(packageName)
                    break

                    case Qt.Key_Back:
                    case Qt.Key_Esc:
                        openAppInfo(packageName)
                    break

                    case Qt.Key_Menu:
                        openSettings()
                    break

                    default:
                        event.accepted = false
                }
            }

            delegate: Rectangle
            {
                property bool isCurrentItem: GridView.isCurrentItem

                width: appGrid.cellWidth - 10
                height: width * 0.5625 // 9/16

                color: "#333333"

                z: isCurrentItem ? 1 : 0
                scale: isCurrentItem ? 1.3 : 1
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }

                Image
                {
                    id: image

                    anchors.fill: parent
                    anchors.margins: isTelevision ? 0 : 30

                    source: "image://icon/" + modelData.packageName
                    asynchronous: true
                    fillMode: Image.PreserveAspectFit
                }

                // app name background so it's readable on any background image
                Rectangle
                {
                    visible: isTelevision && isCurrentItem
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
                    text: modelData.applicationName
                    color: "#ffffff"
                    elide: Text.ElideRight
                    anchors.bottom: parent.bottom
                    visible: isCurrentItem || !isTelevision
                    horizontalAlignment: Text.AlignHCenter
                }

                // border around current item
                Rectangle
                {
                    anchors.fill: parent
                    visible: isCurrentItem
                    color: "transparent"
                    border.width: 1
                    border.color: "#222222"
                }

                MouseArea
                {
                    anchors.fill: parent
                    // open application on mouse click/finger tap
                    onClicked:
                    {
                        appGrid.currentIndex = index
                        openApplication(modelData.packageName)
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
        onClosed: appGrid.focus = true

        Column
        {
            anchors.centerIn: parent
            spacing: 10

            Label
            {
                textFormat: Text.StyledText
                font.pixelSize: 20
                text: `<p>Thanks for using <strong>LetiHome</strong> application!</p><br/>
                <strong>LetiHome</strong> is a lightweight app launcher application<br/>
                that aims to works on as many TV devices as possible, <br/>especially low power ones.<br/><br/>
                As there is <u>zero</u> data collection, please provide your feedback <br/>and suggestions on project source page.<br/>
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
                }
            }
        }
    }
}
