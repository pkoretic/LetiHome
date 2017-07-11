import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Window 2.3

Window
{
    visible: true
    title: qsTr("LetiHome")

    // this is set to native resolution on android
    width: 1920
    height: 1080

    // slightly transparent background
    color: "#aa000000"

    // main date object
    property var date

    // load apps when component is ready
    Component.onCompleted: all.model = __platform.applicationList()

    // when packages are changed (installed/removed) update list
    Connections
    {
        target: __platform
        onPackagesChanged: all.model = __platform.applicationList()
    }

    // clock and date timer
    // update in acceptable interval and ignore updates if application is not shown
    Timer
    {
        running: Qt.application.state === Qt.ApplicationActive
        interval: 5000
        repeat: true
        triggeredOnStart: true
        onTriggered: date = new Date()
    }

    // wrapper item used for padding, spacing and layout
    ColumnLayout
    {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 30

        Item
        {
            height: childrenRect.height
            Layout.fillWidth: true

            // clock in locale format depenending if 24 hour format is set or not in the system
            Text
            {
                text: Qt.formatTime(date, __platform.is24HourFormat() ? "hh:mm" : "hh:mm ap")
                font.pixelSize: 22
                font.italic: true
                color: "#ffffff"
            }

            // date in system locale format
            Text
            {
                text: Qt.formatDate(date, Qt.SystemLocaleLongDate)
                font.pixelSize: 20
                font.italic: true
                color: "#ffffff"
                anchors.right: parent.right
            }
        }

        // main application grid
        GridView
        {
           id: all

           boundsBehavior: GridView.StopAtBounds

           focus: true

           Layout.fillHeight: true
           Layout.preferredWidth: Math.min(model.length, Math.floor(parent.width/cellWidth)) * cellWidth
           anchors.horizontalCenter: parent.horizontalCenter

           cellWidth: Math.max(Math.min(160, Math.min(parent.width, parent.height) / 5), 80)
           cellHeight: cellWidth + 80

           highlight: Rectangle
           {
               color: "#cc000000"
               border.width: 2
               border.color: "#ccffffff"
               radius: 3
               scale: 1.1
           }

           highlightMoveDuration: 50

           // additional keys handling, default navigation is handled by gridview
           Keys.onPressed:
           {
               switch(event.key)
               {
                   case Qt.Key_Enter:
                   case Qt.Key_Return:
                       __platform.launchApplication(model[currentIndex].packageName)
                       event.accepted = true
                   break

                   case Qt.Key_Menu:
                   case Qt.Key_Back:
                       __platform.pickWallpaper()
                       event.accepted = true
                   break
               }
           }

           // enable click support
           delegate: MouseArea
           {
               property bool isCurrent: GridView.isCurrentItem
               acceptedButtons: Qt.LeftButton | Qt.RightButton

               width: GridView.view.cellWidth
               height: childrenRect.height

               // on left click open app, on right click open wallpaper picker
               onClicked: mouse.button === Qt.LeftButton
                          && __platform.launchApplication(modelData.packageName)
                          || __platform.pickWallpaper()

               Image
               {
                   id: icon
                   source: "image://icon/" + modelData.packageName
                   width: parent.width - x * 2
                   height: width
                   asynchronous: true
                   fillMode: Image.PreserveAspectFit
                   x: 15
               }

               Text
               {
                   id: applicationName
                   text: modelData.applicationName
                   color: "#ffffff"
                   style: Text.Outline
                   width: parent.width
                   wrapMode: Label.WordWrap
                   elide: Label.ElideRight
                   horizontalAlignment: Label.AlignHCenter
                   font.bold: isCurrent
                   anchors.top: icon.bottom
                   anchors.topMargin: 5
               }
           }
        }
    }
}
