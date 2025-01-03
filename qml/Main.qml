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

    color: "#aa000000" // QTBUG-132497

    // main date object
    property date currentDate: new Date()

    // load apps when component is ready
    Component.onCompleted: grid.model = __platform.applicationList()

    // when packages are changed (installed/removed) update list
    Connections
    {
        target: __platform
        onPackagesChanged: () => grid.model = __platform.applicationList()
    }

    // random wallpaper
    Image {
        source: "https://picsum.photos/1920/1080"
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

            // clock in locale format depending if 24 hour format is set in the system
            Text
            {
                text: Qt.formatTime(root.currentDate, __platform.is24HourFormat() ? "hh:mm" : "hh:mm ap")
                font.pixelSize: 22
                font.italic: true
                color: "#ffffff"
            }

            // date in system locale format
            Text
            {
                text: root.currentDate.toLocaleDateString()
                font.pixelSize: 20
                font.italic: true
                color: "#ffffff"
                anchors.right: parent.right
            }
        }

        // main application grid
        GridView
        {
            id: grid

            boundsBehavior: GridView.StopAtBounds

            focus: true
            clip: true

            Layout.fillHeight: true
            Layout.preferredWidth: Math.min(model.length, Math.floor(parent.width/cellWidth)) * cellWidth
            Layout.alignment: Qt.AlignHCenter

            cellHeight: grid.height / 3.4 // show a bit of next row
            cellWidth: cellHeight

            highlight: Rectangle
            {
                color: "#cc000000"
                border.width: 1
                border.color: "#cc666666"
                radius: 12
            }

            highlightMoveDuration: 100

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

            // enable click support
            delegate: MouseArea
            {
                id: mouseArea
                property bool isCurrent: GridView.isCurrentItem

                width: GridView.view.cellWidth - 10
                height: GridView.view.cellHeight - 10

                // open application on click
                onClicked:
                {
                    grid.currentIndex = index
                    __platform.launchApplication(modelData.packageName)
                }

                ColumnLayout
                {
                    anchors.fill: parent
                    anchors.margins: 10
                    Image
                    {
                        source: "image://icon/" + modelData.packageName
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        asynchronous: true
                        fillMode: Image.PreserveAspectFit
                    }

                    Text
                    {
                        text: modelData.applicationName
                        font.pixelSize: 14
                        color: "#ffffff"
                        style: Text.Outline
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        elide: Label.ElideRight
                        horizontalAlignment: Label.AlignHCenter
                        font.bold: mouseArea.isCurrent
                    }
                }
            }
        }
    }
}
