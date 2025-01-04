import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window
{
    id: root

    title: qsTr("LetiHome")

    // this is set to native resolution on android
    width: 1920
    height: 1080

    visible: true
    visibility: Window.FullScreen

    // color: "#bb000000" // QTBUG-132497

    // main date object
    property date currentDate: new Date()

    // load apps when component is ready
    Component.onCompleted: connections.onPackagesChanged()

    // when packages are changed (installed/removed) update list
    Connections
    {
        id: connections
        target: __platform
        function onPackagesChanged() { appGrid.model = __platform.applicationList() }
    }

    // random wallpaper
    Image {
        source: "https://picsum.photos/720/576"
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        smooth: false

        Rectangle {
            anchors.fill: parent
            color: "#aa000000"
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
        anchors.margins: 20
        spacing: 20

        Item
        {
            Layout.fillWidth: true
            height: childrenRect.height

            z: 1

            // clock in locale format depending if 24 hour format is set in the system
            Text
            {
                text: Qt.formatTime(root.currentDate, __platform.is24HourFormat() ? "hh:mm" : "hh:mm ap")
                font.pixelSize: 22
                font.italic: true
                color: "#ffffff"
                style: Text.Outline
            }

            // date in system locale format
            Text
            {
                text: root.currentDate.toLocaleDateString()
                font.pixelSize: 20
                font.italic: true
                color: "#ffffff"
                anchors.right: parent.right
                style: Text.Outline
            }
        }

        // main application grid
        GridView
        {
            id: appGrid

            boundsBehavior: GridView.StopAtBounds

            focus: true
            // clip: true

            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter

            cellWidth: (width / 5) |0
            cellHeight: cellWidth * 9/16

            // additional keys handling, default navigation is handled by gridview
            property int keyPressCount: 0

            // long press handling
            Keys.onPressed: (event) => ++keyPressCount
            Keys.onReleased: function (event) {
                switch(event.key) {
                case Qt.Key_Enter:
                case Qt.Key_Return:
                    event.accepted = true

                    if (keyPressCount > 2) {
                        keyPressCount = 0
                        // long press detected
                    }

                    else {
                        __platform.launchApplication(model[currentIndex].packageName)
                    }
                    break

                case Qt.Key_Menu:
                case Qt.Key_Back:
                    event.accepted = true

                    __platform.pickWallpaper()
                    break

                default:
                    keyPressCount = 0
                }
            }

            delegate: Rectangle
            {
                property bool isCurrentItem: GridView.isCurrentItem

                width: appGrid.cellWidth
                height: appGrid.cellHeight

                color: "#333333"

                z: isCurrentItem ? 1 : 0
                scale: isCurrentItem ? 1.2 : 0.9
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }

                Image {
                    id: image

                    anchors.fill: parent
                    anchors.margins: 1

                    source: "image://icon/" + modelData.packageName
                    asynchronous: true
                    fillMode: Image.PreserveAspectFit
                }

                // app name background so it's readable on any background image
                Rectangle
                {
                    visible: isCurrentItem
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
                    visible: isCurrentItem
                    horizontalAlignment: Text.AlignHCenter
                }

                MouseArea
                {
                    anchors.fill: parent
                    // open application on mouse click/finger tap
                    onClicked:
                    {
                        appGrid.currentIndex = index
                        __platform.launchApplication(modelData.packageName)
                    }
                }
            }
        }
    }
}
