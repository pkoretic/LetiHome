import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11
import QtQuick.Window 2.11

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
        anchors.margins: 25
        spacing: 25

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
           clip: true

           Layout.fillHeight: true
           Layout.preferredWidth: Math.min(model.length, Math.floor(parent.width/cellWidth)) * cellWidth
           anchors.horizontalCenter: parent.horizontalCenter

           cellWidth: 160
           cellHeight: 160

           highlight: Rectangle
           {
               color: "#cc000000"
               border.width: 2
               border.color: "#ccffffff"
               radius: 3
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

               width: GridView.view.cellWidth - 10
               height: GridView.view.cellHeight - 10

               // open application on click
               onClicked: __platform.launchApplication(modelData.packageName)

               ColumnLayout
               {
                   anchors.fill: parent
                   anchors.margins: 15
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
                       color: "#ffffff"
                       style: Text.Outline
                       Layout.fillWidth: true
                       wrapMode: Text.WordWrap
                       elide: Label.ElideRight
                       horizontalAlignment: Label.AlignHCenter
                       font.bold: isCurrent
                   }
               }
           }
        }
    }
}
