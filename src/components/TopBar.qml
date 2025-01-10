import QtQuick

Item
{
    id: root

    property var currentDate: new Date()
    property bool is24HourFormat: true
    property bool isOnline: true
    property alias running: updateTimer.running

    // clock in locale format depending if 24 hour format is set in the system
    Text
    {
        id: datetime
        text: Qt.formatTime(root.currentDate, root.is24HourFormat ? "hh:mm" : "hh:mm ap")
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
            source: "../../assets/network-%1.svg".arg(root.isOnline ? "online" : "offline")
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

    // update in acceptable interval and ignore updates if application is not active (another app open)
    Timer
    {
        id: updateTimer
        interval: 5000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.currentDate = new Date()
    }
}
