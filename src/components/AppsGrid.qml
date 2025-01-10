import QtQuick

import "ColorLogo.js" as ColorLogo

// Grid view of applications
GridView
{
    id: gridView

    signal keyPressed(var event)
    signal clicked(string packageName)

    property bool isTelevision

    boundsBehavior: GridView.StopAtBounds

    cellWidth: (width / 5) |0
    cellHeight: cellWidth * 0.5625 // 9/16

    Keys.onPressed: event => keyPressed(event)

    delegate: Rectangle
    {
        id: delegate

        property bool isCurrentItem: GridView.isCurrentItem

        width: GridView.view.cellWidth - 20
        height: width * 0.5625 // 9/16

        color: gridView.isTelevision ? "#333333" :  ColorLogo.createByIndex(index)

        z: delegate.isCurrentItem ? 1 : 0
        scale: delegate.isCurrentItem ? 1.3 : 1
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }

        required property int index
        required property var modelData

        Image
        {
            id: image

            anchors.fill: parent
            anchors.margins: gridView.isTelevision || isTVIcon ? 0 : 20
            source: "image://icon/" + modelData.packageName
            asynchronous: true
            fillMode: Image.PreserveAspectFit

            property bool isTVIcon: sourceSize.height != sourceSize.width
        }

        // app name background so it's readable on any background image
        Rectangle
        {
            visible: gridView.isTelevision && delegate.isCurrentItem
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
            visible: delegate.isCurrentItem || !gridView.isTelevision
            horizontalAlignment: Text.AlignHCenter
        }

        // border around current item
        Rectangle
        {
            anchors.fill: parent
            visible: delegate.isCurrentItem
            color: "transparent"
            border.width: 2
            border.color: "#222222"
        }

        // open application on mouse click/finger tap
        MouseArea
        {
            anchors.fill: parent
            onClicked:
            {
                gridView.currentIndex = index
                gridView.clicked(modelData.packageName)
            }
        }
    }
}
