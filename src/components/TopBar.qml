import QtQuick

FocusScope
{
    id: root

    property var currentDate: new Date()
    property bool is24HourFormat: true
    property bool isOnline: true
    property bool isEthernet: true
    property alias running: updateTimer.running
    property bool showClock
    property alias showDate: date.visible

    implicitHeight: childrenRect.height

    signal settingsClicked

    // clock in locale format depending if 24 hour format is set in the system
    Text
    {
        id: time
        text: Qt.formatTime(root.currentDate, root.is24HourFormat ? "hh:mm" : "hh:mm ap")
        font.pixelSize: 22
        color: Qt.color("#ffffff")
        style: Text.Outline
        visible: showClock
    }

    Row
    {
        anchors.right: parent.right
        spacing: 10

        Image
        {
            source: "../../assets/%1.svg".arg(root.isOnline ? (root.isEthernet ? "ethernet-online" : "wifi-online") : "network-offline")
            height: time.height - 10
            width: height
            onStatusChanged: {
                if (status === Image.Ready) {
                    sourceSize.width = paintedWidth
                    sourceSize.height = paintedHeight
                }
            }
            anchors.verticalCenter: parent.verticalCenter
        }

        Image
        {
            focus: true
            source: "../../assets/settings%1.svg".arg(activeFocus ? "-active" : "")
            scale: activeFocus ? 1.5 : 1
            height: time.height - 10
            width: height
            onStatusChanged: {
                if (status === Image.Ready) {
                    sourceSize.width = paintedWidth
                    sourceSize.height = paintedHeight
                }
            }
            anchors.verticalCenter: parent.verticalCenter

            Keys.onReturnPressed: root.settingsClicked()
            Keys.onEnterPressed: root.settingsClicked()
        }

        // date in system locale format
        Text
        {
            id: date
            text: root.currentDate.toDateString()
            font.pixelSize: 22
            color: Qt.color("#ffffff")
            style: Text.Outline
        }
    }

    // update in acceptable interval and ignore updates if application is not active (another app open)
    Timer
    {
        id: updateTimer
        running: root.showClock && Application.state == Qt.ApplicationActive
        interval: 5000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.currentDate = new Date()
    }
}
