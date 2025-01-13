pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Material

import "ColorLogo.js" as ColorLogo

// Grid view of applications
GridView
{
    id: gridView

    signal openClicked(string packageName)
    signal infoClicked(string packageName)
    signal appHidden(string packageName)

    function openContextualMenu()
    {
       contextMenu.popup(gridView.currentItem)
    }

    property bool isTelevision
    property bool showAppLabels

    boundsBehavior: GridView.StopAtBounds

    cellWidth: (width / 5) |0
    cellHeight: cellWidth * 0.5625 // 9/16

    Keys.onRightPressed: event => {
        if (state === "reoder") {
            const currentIndex = gridView.currentIndex
            gridView.model = moveAppForward(gridView.model, currentIndex)
            gridView.currentIndex = currentIndex < gridView.model.length - 1 ? currentIndex + 1 : currentIndex
        }
        else
            event.accepted = false
    }

    Keys.onLeftPressed: event => {
        if (state === "reoder") {
            const currentIndex = gridView.currentIndex
            gridView.model = moveAppBackward(gridView.model, currentIndex)
            gridView.currentIndex = currentIndex > 0 ? currentIndex - 1 : currentIndex
        }
        else
            event.accepted = false
    }
    Keys.onEscapePressed: event => {
        if (state === "reoder")
            state = "default"
        else
            event.accepted = false
    }

    state: "default"
    states: [
        State { name: "default" },
        State { name: "reoder" }
    ]

    function moveAppForward(array, index) {
        if (index < array.length - 1) {
            // Swap with the next item
            [array[index], array[index + 1]] = [array[index + 1], array[index]]
        }
        return array
    }

    function moveAppBackward(array, index)
    {
        if (index > 0) {
            // Swap with the previous item
            [array[index], array[index - 1]] = [array[index - 1], array[index]]
        }
        return array
    }

    // Contextual menu
    Menu
    {
        id: contextMenu
        MenuItem
        {
            text: "Open"
            onTriggered: gridView.openClicked(gridView.model[gridView.currentIndex].packageName)
        }
        MenuItem
        {
            text: "Reorder"
            onTriggered: gridView.state = "reoder"
        }
        MenuItem
        {
            text: "Info"
            onTriggered: gridView.infoClicked(gridView.model[gridView.currentIndex].packageName)
        }
        MenuItem
        {
            text: "Hide"
            onTriggered:
            {
                const model = gridView.model
                const currentIndex = gridView.currentIndex
                model.splice(gridView.currentIndex, 1)
                gridView.model = model
                gridView.currentIndex = currentIndex - 1
                // gridView.hideClicked(gridView.model[gridView.currentIndex].packageName)
            }
        }
    }

    delegate: Rectangle
    {
        id: delegate

        property bool isCurrentItem: GridView.isCurrentItem

        width: GridView.view.cellWidth - 20
        height: width * 0.5625 // 9/16

        color: gridView.isTelevision ? "#333333" :  ColorLogo.createByName(modelData.applicationName)

        z: delegate.isCurrentItem ? 1 : 0
        scale: delegate.isCurrentItem && gridView.state === "default" ? 1.3 : 1
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
            visible: gridView.showAppLabels && gridView.isTelevision && delegate.isCurrentItem
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
            visible: gridView.showAppLabels && delegate.isCurrentItem || !gridView.isTelevision
            horizontalAlignment: Text.AlignHCenter
        }

        // border around current item
        Rectangle
        {
            anchors.fill: parent
            visible: delegate.isCurrentItem
            color: "transparent"
            border.width: gridView.state === "reoder" ? 3 : 2
            border.color: gridView.state === "reoder" ? "red" : "#222222"
        }

        // open application on mouse click/finger tap
        MouseArea
        {
            anchors.fill: parent
            onClicked:
            {
                gridView.currentIndex = index
                gridView.openClicked(modelData.packageName)
            }
        }
    }
}
